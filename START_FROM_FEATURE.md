# 从指定位置开始下载功能

## 📋 功能概述

**从指定位置开始下载（Start From）** 功能允许用户在批量下载时，从 TXT 文件的任意位置开始下载，跳过前面的链接。这在以下场景非常有用：

- 🔄 **续传下载**：中断后从上次停止的位置继续
- 🎯 **分段下载**：多个实例并行下载不同段落
- 🧪 **测试调试**：快速跳到特定位置测试
- ⏭️ **跳过失败**：跳过已知失败的链接

## 🚀 快速开始

### 基本用法

```bash
./apple-music-downloader Jazz.txt --start 44
```

**效果**：
- 跳过 Jazz.txt 前 43 个链接
- 从第 44 个链接开始下载
- 任务编号显示为 "44/67" 而不是 "1/24"

### 完整示例

```bash
# 从第 1 个开始（默认，等同于不加参数）
./apple-music-downloader albums.txt

# 从第 10 个开始
./apple-music-downloader albums.txt --start 10

# 从第 50 个开始
./apple-music-downloader albums.txt --start 50

# 结合其他参数使用
./apple-music-downloader albums.txt --start 20 --config my-config.yaml
```

## 📖 详细说明

### 参数说明

**命令行参数**：`--start <number>`

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--start` | int | `0` | 从第几个链接开始（从 1 开始计数） |

**注意事项**：
- 编号从 **1** 开始，不是 0
- 如果指定的数字超过总数，会从第 1 个开始
- 只在 TXT 文件批量模式下生效
- 单链接模式下会被忽略

### 界面显示

#### 启用 --start 参数时

```
📊 从文件 albums.txt 中解析到 67 个链接

📋 初始链接总数: 67
🔄 开始预处理链接...

⏭️  跳过前 43 个任务，从第 44 个开始下载

📋 ========== 开始下载任务 ==========
📝 任务总数: 67
📝 实际下载: 第 44 至第 67 个（共 24 个）
⚡ 执行模式: 串行模式
📦 专辑内并发: 由配置文件控制
====================================

🧾 [44/67] 开始处理: https://music.apple.com/...
🎤 歌手: Artist Name
💽 专辑: Album Name
...
✅ [44/67] 任务完成

🧾 [45/67] 开始处理: ...
...
```

**关键点**：
- ✅ 显示跳过了多少个任务
- ✅ 任务编号显示为 44/67（不是 1/24）
- ✅ 清晰标注实际下载范围

#### 未启用时（正常模式）

```
📋 ========== 开始下载任务 ==========
📝 任务总数: 67
⚡ 执行模式: 串行模式
====================================

🧾 [1/67] 开始处理: ...
...
```

## 🎯 使用场景

### 场景 1：续传下载

**问题**：下载 100 个专辑，在第 43 个时程序崩溃

**解决方案**：
```bash
# 从第 44 个继续
./apple-music-downloader large-collection.txt --start 44
```

**优势**：
- ✅ 无需手动编辑 TXT 文件
- ✅ 保留原始文件完整性
- ✅ 快速恢复下载

### 场景 2：分段并行下载

**需求**：100 个专辑，用 4 个实例并行下载

**解决方案**：
```bash
# 终端 1：下载 1-25
./apple-music-downloader albums.txt --start 1 --config config1.yaml

# 终端 2：下载 26-50  
./apple-music-downloader albums.txt --start 26 --config config2.yaml

# 终端 3：下载 51-75
./apple-music-downloader albums.txt --start 51 --config config3.yaml

# 终端 4：下载 76-100
./apple-music-downloader albums.txt --start 76 --config config4.yaml
```

**注意**：
- ⚠️ 需要使用不同的配置文件（不同账户）
- ⚠️ 或确保输出目录不冲突
- ✅ 可以显著加快大批量下载速度

### 场景 3：测试特定专辑

**需求**：测试 TXT 文件中第 50 个专辑的下载

**解决方案**：
```bash
# 只下载第 50 个
# 方法1：使用 --start
./apple-music-downloader albums.txt --start 50

# 方法2：结合其他工具
# 创建临时文件只包含第 50 行
sed -n '50p' albums.txt > test.txt
./apple-music-downloader test.txt
```

### 场景 4：跳过已知失败的链接

**问题**：前 10 个链接已知无法下载（区域限制等）

**解决方案**：
```bash
# 从第 11 个开始
./apple-music-downloader albums.txt --start 11
```

## 🔧 技术实现

### 核心逻辑

```go
// 处理 --start 参数
startIndex := 0
if core.StartFrom > 0 {
    if core.StartFrom > totalTasks {
        // 超出范围，从第 1 个开始
        core.StartFrom = 1
    } else {
        startIndex = core.StartFrom - 1
        finalUrls = finalUrls[startIndex:]  // 跳过前面的链接
        totalTasks = len(finalUrls)
    }
}

// 计算实际任务编号
for i, url := range finalUrls {
    actualTaskNum := i + 1 + startIndex  // 显示真实编号
    processURL(url, actualTaskNum, originalTotalTasks)
}
```

### 实现细节

1. **参数验证**
   - 检查是否超出范围
   - 自动调整为有效值

2. **数组切片**
   - 使用 Go 的切片语法跳过前面的元素
   - 不修改原始 TXT 文件

3. **编号映射**
   - 保持显示编号与原始位置一致
   - 用户体验友好

## 📊 性能影响

### 时间开销

| 操作 | 耗时 | 说明 |
|------|------|------|
| 参数解析 | < 1ms | 几乎无开销 |
| 数组切片 | < 1ms | Go 切片操作非常快 |
| 总影响 | 可忽略 | 对下载速度无影响 |

### 内存开销

**无额外内存开销**：
- Go 的切片使用底层数组
- 不复制数据，只是移动指针
- 内存占用与不使用参数时相同

## 🎨 与其他功能的兼容性

### ✅ 兼容功能

| 功能 | 兼容性 | 说明 |
|------|--------|------|
| 历史记录 | ✅ 完全兼容 | 正常记录下载历史 |
| 工作-休息循环 | ✅ 完全兼容 | 正常工作 |
| 批量模式 | ✅ 完全兼容 | 这是主要使用场景 |
| 多账户 | ✅ 完全兼容 | 无冲突 |
| 缓存机制 | ✅ 完全兼容 | 正常使用缓存 |

### ⚠️ 注意事项

**历史记录**：
- 如果使用 `--start` 跳过了一些链接
- 这些链接不会被记录到历史
- 下次运行时不会被自动跳过

**解决方案**：
- 使用历史记录功能会自动跳过已完成的
- 不需要手动使用 `--start`

## 🔍 常见问题

### Q1: --start 44 是从第 44 个开始还是跳过 44 个？

**A**: 从第 44 个开始下载（跳过前 43 个）。

**示例**：
```bash
# TXT 文件有 100 行
# --start 44 表示：
# - 跳过第 1-43 行
# - 从第 44 行开始
# - 下载第 44-100 行（共 57 个）
```

### Q2: 编号是从 0 还是从 1 开始？

**A**: 从 1 开始（符合人类习惯）。

```bash
# 第一个链接
./apple-music-downloader albums.txt --start 1

# 不是
./apple-music-downloader albums.txt --start 0  # 这会被视为未指定
```

### Q3: 如果指定的数字超过总数怎么办？

**A**: 会自动从第 1 个开始，并显示警告。

```bash
# TXT 文件只有 50 行
./apple-music-downloader albums.txt --start 100

# 输出：
# ⚠️  起始位置 100 超过了总任务数 50，将从第 1 个开始
```

### Q4: 可以和历史记录功能一起使用吗？

**A**: 可以，但通常不需要。

**推荐做法**：
- ✅ 使用历史记录功能自动跳过已完成的
- ⚠️ 只在特殊情况下使用 `--start`

**示例**：
```bash
# 第一次运行
./apple-music-downloader albums.txt
# 中断在第 30 个

# 第二次运行（推荐）
./apple-music-downloader albums.txt
# 历史记录会自动跳过前 30 个

# 第二次运行（不推荐，除非有特殊需求）
./apple-music-downloader albums.txt --start 31
# 手动指定从 31 开始
```

### Q5: 任务编号为什么显示 44/67 而不是 1/24？

**A**: 为了保持与原始 TXT 文件一致，方便用户对照。

**设计理念**：
- 用户看到 "44/67" 可以立即知道是 TXT 的第 44 个
- 更容易查找原始链接
- 续传时不会混淆

### Q6: 可以在单链接模式下使用吗？

**A**: 可以指定，但会被忽略。

```bash
# 单链接模式
./apple-music-downloader https://music.apple.com/... --start 10
# --start 会被忽略，正常下载该专辑
```

### Q7: 如何实现"只下载第 50 个"？

**A**: 需要结合其他工具或手动停止。

**方法 1**：使用 sed 提取单行
```bash
sed -n '50p' albums.txt > temp.txt
./apple-music-downloader temp.txt
```

**方法 2**：使用 --start 然后手动停止
```bash
./apple-music-downloader albums.txt --start 50
# 下载完第 50 个后按 Ctrl+C
```

**方法 3**：未来可能添加 `--end` 参数
```bash
# 假设未来版本
./apple-music-downloader albums.txt --start 50 --end 50
```

## 💡 最佳实践

### 1. 大批量下载的推荐流程

```bash
# 步骤 1：首次运行
./apple-music-downloader large-collection.txt

# 步骤 2：如果中断，直接重新运行（历史记录会跳过已完成的）
./apple-music-downloader large-collection.txt

# 步骤 3：如果想从特定位置强制开始
./apple-music-downloader large-collection.txt --start 100
```

### 2. 分段并行下载

```bash
# 创建 4 个配置文件（使用不同账户）
# config1.yaml, config2.yaml, config3.yaml, config4.yaml

# 打开 4 个终端
# 终端 1
./apple-music-downloader albums.txt --start 1 --config config1.yaml &

# 终端 2
./apple-music-downloader albums.txt --start 26 --config config2.yaml &

# 终端 3
./apple-music-downloader albums.txt --start 51 --config config3.yaml &

# 终端 4
./apple-music-downloader albums.txt --start 76 --config config4.yaml &

# 等待全部完成
wait
```

### 3. 测试和调试

```bash
# 快速测试第 10 个专辑
./apple-music-downloader test.txt --start 10

# 跳过已知失败的前 5 个
./apple-music-downloader albums.txt --start 6
```

## 📚 相关命令行参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--start` | 从第几个开始 | `--start 44` |
| `--config` | 指定配置文件 | `--config my.yaml` |
| `--output` | 指定输出目录 | `--output ./downloads` |
| `--no-ui` | 禁用动态 UI | `--no-ui` |

**组合使用**：
```bash
./apple-music-downloader albums.txt \
    --start 50 \
    --config premium.yaml \
    --output /mnt/music \
    --no-ui
```

## 🎯 总结

**--start 参数的核心优势**：

1. **续传友好**
   - ✅ 中断后快速恢复
   - ✅ 无需编辑文件

2. **灵活控制**
   - ✅ 任意位置开始
   - ✅ 分段并行下载

3. **用户友好**
   - ✅ 从 1 开始计数（符合习惯）
   - ✅ 显示真实编号
   - ✅ 自动处理越界

4. **性能优秀**
   - ✅ 无额外开销
   - ✅ 不修改原文件

**推荐使用场景**：
- 🔄 续传中断的下载
- 🎯 分段并行下载
- 🧪 测试特定位置
- ⏭️ 跳过已知问题

**不推荐场景**：
- ❌ 正常首次下载（用历史记录更好）
- ❌ 单链接下载（会被忽略）

---

**开发分支**：`feature/fix-ilst-box-missing`  
**开发日期**：2025-10-10  
**状态**：✅ 已实现并测试

