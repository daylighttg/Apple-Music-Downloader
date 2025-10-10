# 下载逻辑问题详细分析

## 📊 当前实现 vs 期望逻辑对比

### ✅ 已正确实现的部分

1. **单曲去重** (downloadTrackSilently, 第413-436行)
   - ✅ 使用缓存时，检查最终目标路径
   - ✅ 文件已存在则跳过下载
   - ✅ 返回已存在文件的路径

2. **专辑去重** (Rip, 第776-853行)
   - ✅ 检查所有选中曲目
   - ✅ 全部存在时跳过整个专辑
   - ✅ 避免进入下载循环

3. **下载到缓存** (第438-455行)
   - ✅ 新文件下载到缓存路径
   - ✅ 在缓存完成加工（FFmpeg、标签）

4. **批次转移** (第1078-1131行)
   - ✅ 批次完成后转移文件
   - ✅ 避免缓存堆积

5. **清理缓存** (第1200-1203行)
   - ✅ 转移完成后清理缓存

## ❌ 存在的问题

### 问题1：SafeMoveFile 会覆盖已存在文件

**位置**：`internal/utils/helpers.go` 第168-224行

**问题代码**：
```go
func SafeMoveFile(src, dst string) error {
    // 确保目标目录存在
    dstDir := filepath.Dir(dst)
    if err := os.MkdirAll(dstDir, os.ModePerm); err != nil {
        return fmt.Errorf("创建目标目录失败: %w", err)
    }

    // 首先尝试直接重命名（最快的方式）
    if err := os.Rename(src, dst); err == nil {
        return nil  // ← 问题：如果dst已存在，os.Rename会覆盖！
    }

    // 如果重命名失败，使用拷贝+删除
    // ... 拷贝逻辑 ...
    // ← 问题：这里也会覆盖已存在的文件
}
```

**影响**：
- 如果目标文件已存在，会被覆盖
- 虽然下载逻辑已经跳过了已存在的文件
- 但如果缓存中有残留文件，转移时会覆盖目标

### 问题2：缓存转移时未做文件存在检查

**位置**：第1183行

**问题代码**：
```go
// 转移文件
if err := utils.SafeMoveFile(cachePath, targetPath); err != nil {
    fmt.Printf("警告: 转移文件失败 %s: %v\n", relPath, err)
}
```

**应该是**：
```go
// 检查目标文件是否已存在
exists, _ := utils.FileExists(targetPath)
if exists {
    // 跳过，不覆盖
    continue
}

// 转移文件
if err := utils.SafeMoveFile(cachePath, targetPath); err != nil {
    fmt.Printf("警告: 转移文件失败 %s: %v\n", relPath, err)
}
```

### 问题3：没有真正的"增量下载"支持

**期望行为**：
```
专辑有10首，本地已有5首
→ 只下载另外5首
→ 只转移新下载的5首
→ 不影响已有的5首
```

**当前行为**：
```
专辑有10首，本地已有5首
→ 检查到不是全部存在（allFilesExist=false）
→ 进入下载循环
→ 已存在的5首被跳过（downloadTrackSilently检查）✅
→ 下载新的5首到缓存 ✅
→ 转移时：
   - 如果缓存只有新的5首：正常 ✅
   - 如果缓存有残留（旧的10首）：可能覆盖目标 ❌
```

**根本问题**：
- 转移逻辑是"盲目转移缓存中所有文件"
- 没有检查目标文件是否已存在
- 依赖"缓存只有新文件"的假设（不可靠）

## 🔧 建议的修复方案

### 修复1：SafeMoveFile 添加存在检查选项

```go
// SafeMoveFile 添加参数控制是否覆盖
func SafeMoveFile(src, dst string, overwrite bool) error {
    // 检查目标文件是否存在
    if !overwrite {
        exists, _ := FileExists(dst)
        if exists {
            return fmt.Errorf("目标文件已存在，跳过")
        }
    }
    
    // ... 原有逻辑 ...
}
```

### 修复2：转移逻辑添加存在检查

```go
// 转移文件
if info.IsDir() {
    return os.MkdirAll(targetPath, info.Mode())
}

// ✅ 检查目标文件是否已存在
targetExists, _ := utils.FileExists(targetPath)
if targetExists {
    // 跳过，不覆盖已存在文件
    return nil
}

// 转移文件
if err := utils.SafeMoveFile(cachePath, targetPath, false); err != nil {
    fmt.Printf("警告: 转移文件失败 %s: %v\n", relPath, err)
}
```

### 修复3：批次转移也添加检查

```go
// 批次转移（第1078-1131行）
if info.IsDir() {
    os.MkdirAll(targetPath, info.Mode())
} else if strings.HasSuffix(cachePath, ".m4a") || strings.HasSuffix(cachePath, ".jpg") {
    // ✅ 检查目标文件是否已存在
    targetExists, _ := utils.FileExists(targetPath)
    if !targetExists {
        if err := utils.SafeMoveFile(cachePath, targetPath, false); err == nil {
            moveCount++
        }
    }
}
```

## 📝 完整的修复流程

### Step 1: 修改 SafeMoveFile 函数

```go
func SafeMoveFile(src, dst string) error {
    // 1. 检查目标文件是否已存在
    targetExists, _ := FileExists(dst)
    if targetExists {
        // 跳过，返回特殊错误
        return fmt.Errorf("目标文件已存在")
    }
    
    // 2. 确保目标目录存在
    dstDir := filepath.Dir(dst)
    if err := os.MkdirAll(dstDir, os.ModePerm); err != nil {
        return fmt.Errorf("创建目标目录失败: %w", err)
    }

    // 3. 原有的移动逻辑...
}
```

### Step 2: 修改转移逻辑（最终转移）

```go
// 递归转移所有子目录
moveErr := filepath.Walk(cacheHashDir, func(cachePath string, info os.FileInfo, walkErr error) error {
    // ... 跳过根目录、计算路径 ...
    
    if info.IsDir() {
        return os.MkdirAll(targetPath, info.Mode())
    }
    
    // ✅ 添加：检查目标文件是否已存在
    targetExists, _ := utils.FileExists(targetPath)
    if targetExists {
        // 跳过已存在的文件，不覆盖
        return nil
    }
    
    // 转移文件
    if err := utils.SafeMoveFile(cachePath, targetPath); err != nil {
        if !strings.Contains(err.Error(), "目标文件已存在") {
            fmt.Printf("警告: 转移文件失败 %s: %v\n", relPath, err)
        }
    }
    return nil
})
```

### Step 3: 修改批次转移逻辑

```go
// 递归转移所有文件
moveCount := 0
filepath.Walk(cacheHashDir, func(cachePath string, info os.FileInfo, walkErr error) error {
    // ... 路径处理 ...
    
    if info.IsDir() {
        os.MkdirAll(targetPath, info.Mode())
    } else if strings.HasSuffix(cachePath, ".m4a") || strings.HasSuffix(cachePath, ".jpg") {
        // ✅ 添加：检查目标文件是否已存在
        targetExists, _ := utils.FileExists(targetPath)
        if !targetExists {
            if err := utils.SafeMoveFile(cachePath, targetPath); err == nil {
                moveCount++
            }
        }
    }
    return nil
})
```

## 🎯 修复后的完整流程

### 无差异情况（所有文件都已存在）
```
1. 读取专辑数据
2. 检查所有文件（第776-834行）→ allFilesExist = true
3. 跳过下载（第836-853行）→ return
4. ✅ 不进入下载循环
5. ✅ 不转移任何文件
6. ✅ 不覆盖任何文件
```

### 有差异情况（部分文件已存在）
```
1. 读取专辑数据
2. 检查所有文件 → allFilesExist = false
3. 进入下载循环
   - 对于已存在的文件：
     a. downloadTrackSilently 检查（第429-436行）→ exists = true
     b. 跳过下载 → return returnPath
     c. ✅ 不下载到缓存
   - 对于不存在的文件：
     a. downloadTrackSilently 检查 → exists = false
     b. 下载到缓存（第438-455行）
     c. 在缓存完成加工（FFmpeg、标签）
4. 批次转移/最终转移：
   a. 扫描缓存中的文件
   b. ✅ 检查目标文件是否已存在
   c. ✅ 已存在的跳过，不覆盖
   d. ✅ 只转移新文件
5. 清理缓存
```

## ⚠️ 风险分析

### 当前风险
- **高风险**：缓存中的残留文件可能覆盖目标文件
- **中风险**：SafeMoveFile 默认覆盖行为
- **低风险**：理论上缓存应该是干净的（因为每次都清理）

### 修复后风险
- **无风险**：明确检查目标文件存在性
- **无风险**：即使缓存有残留，也不会覆盖
- **无风险**：真正的增量下载和转移

## 📋 修复优先级

1. **P0（立即修复）**：SafeMoveFile 添加存在检查
2. **P0（立即修复）**：转移逻辑添加存在检查
3. **P1（建议修复）**：批次转移添加存在检查
4. **P2（优化）**：添加日志，记录跳过的文件

---

**结论**：当前逻辑**基本正确**，但缺少关键的**文件存在检查**，可能导致**意外覆盖**。建议立即修复。

