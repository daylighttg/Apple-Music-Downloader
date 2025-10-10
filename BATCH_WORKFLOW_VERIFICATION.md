# 批量下载任务工作流程验证

## 📋 期望的工作流程

```
读取 txt 文件 
  → 清点链接数 
  → 依次读取链接 
  → 串行下载 
  → 完成下载 
  → 移动文件 
  → 继续下载下一个链接
```

## ✅ 当前实际实现

### 1. 读取 TXT 文件（第228-252行）

```go
func parseTxtFile(filePath string) ([]string, error) {
    fileBytes, err := os.ReadFile(filePath)
    if err != nil {
        return nil, fmt.Errorf("读取文件失败: %v", err)
    }

    lines := strings.Split(string(fileBytes), "\n")
    var urls []string
    for _, line := range lines {
        trimmedLine := strings.TrimSpace(line)
        // 跳过空行和注释行（以#开头）
        if trimmedLine == "" || strings.HasPrefix(trimmedLine, "#") {
            continue
        }
        // 支持一行多个链接（空格分隔）
        linksInLine := strings.Fields(trimmedLine)
        for _, link := range linksInLine {
            link = strings.TrimSpace(link)
            if link != "" {
                urls = append(urls, link)
            }
        }
    }
    return urls, nil
}
```

**状态**：✅ **完全符合**
- 读取TXT文件
- 解析每一行
- 支持空格分隔多链接
- 跳过空行和注释

### 2. 清点链接数（第258-261行）

```go
// 显示输入链接统计
if isBatch && len(initialUrls) > 0 {
    core.SafePrintf("📋 初始链接总数: %d\n", len(initialUrls))
    core.SafePrintf("🔄 开始预处理链接...\n\n")
}
```

**状态**：✅ **完全符合**
- 显示初始链接总数
- 提示开始预处理

### 3. 预处理链接（第263-296行）

```go
for _, urlRaw := range initialUrls {
    if strings.Contains(urlRaw, "/artist/") {
        // 处理歌手页面，展开为专辑列表
        albumArgs, err := api.CheckArtist(urlRaw, artistAccount, "albums")
        finalUrls = append(finalUrls, albumArgs...)
        
        mvArgs, err := api.CheckArtist(urlRaw, artistAccount, "music-videos")
        finalUrls = append(finalUrls, mvArgs...)
    } else {
        // 普通链接直接添加
        finalUrls = append(finalUrls, urlRaw)
    }
}
```

**状态**：✅ **符合且增强**
- 支持歌手页面展开
- 预处理后得到最终任务列表

### 4. 计算最终任务数（第303行）

```go
totalTasks := len(finalUrls)
```

**状态**：✅ **完全符合**

### 5. 历史记录过滤（第305-350行）

```go
// 初始化历史记录系统
if isBatch && taskFile != "" {
    // 检查历史记录，获取已完成的URL
    completedURLs, err = history.GetCompletedURLs(taskFile)
    
    // 过滤已完成的URL
    var remainingUrls []string
    for _, url := range finalUrls {
        if completedURLs[url] {
            skippedCount++
        } else {
            remainingUrls = append(remainingUrls, url)
        }
    }
    
    finalUrls = remainingUrls
    totalTasks = len(finalUrls)
}
```

**状态**：✅ **符合且增强**
- 自动跳过已完成的任务
- 显示跳过数量和剩余任务数

### 6. 显示任务统计（第352-367行）

```go
if isBatch {
    core.SafePrintf("\n📋 ========== 开始下载任务 ==========\n")
    if len(initialUrls) != totalTasks {
        core.SafePrintf("📝 预处理完成: %d 个链接 → %d 个任务\n", len(initialUrls), totalTasks)
    } else {
        core.SafePrintf("📝 任务总数: %d\n", totalTasks)
    }
    core.SafePrintf("⚡ 执行模式: 串行模式 \n")
    core.SafePrintf("📦 专辑内并发: 由配置文件控制\n")
    if task != nil {
        core.SafePrintf("📜 历史记录: 已启用\n")
    }
    core.SafePrintf("====================================\n\n")
}
```

**输出示例**：
```
📋 ========== 开始下载任务 ==========
📝 任务总数: 63
⚡ 执行模式: 串行模式 
📦 专辑内并发: 由配置文件控制
📜 历史记录: 已启用
====================================
```

**状态**：✅ **完全符合**

### 7. 串行下载循环（第369-397行）

```go
// 批量模式：串行执行（按链接顺序依次下载）
// 专辑内歌曲并发数由配置文件控制 (lossless_downloadthreads 等)
for i, urlToProcess := range finalUrls {
    albumId, albumName, err := processURL(urlToProcess, nil, nil, i+1, totalTasks)
    
    // 记录到历史
    if task != nil && albumId != "" {
        status := "success"
        errorMsg := ""
        if err != nil {
            status = "failed"
            errorMsg = err.Error()
        }
        
        history.AddRecord(history.DownloadRecord{
            URL:        urlToProcess,
            AlbumID:    albumId,
            AlbumName:  albumName,
            Status:     status,
            DownloadAt: time.Now(),
            ErrorMsg:   errorMsg,
        })
    }
    
    // 任务之间添加视觉间隔（最后一个任务不需要）
    if isBatch && i < len(finalUrls)-1 {
        core.SafePrintf("\n%s\n\n", strings.Repeat("=", 80))
    }
}
```

**关键点**：
- ✅ 使用 `for i, urlToProcess := range finalUrls` - **串行执行**
- ✅ 调用 `processURL` 逐个处理
- ✅ 每个任务完成后记录历史
- ✅ 任务之间添加视觉分隔

**状态**：✅ **完全符合串行模式**

### 8. 单个任务处理（processURL, 第144-217行）

```go
func processURL(urlRaw string, semaphore chan struct{}, wg *sync.WaitGroup, currentTask, totalTasks int) (string, string, error) {
    // 如果是批量模式（semaphore为nil），串行执行
    // 如果是非批量模式，使用semaphore控制并发
    
    if isBatch {
        core.SafePrintf("🧾 [%d/%d] 开始处理: %s\n", currentTask, totalTasks, urlRaw)
    }
    
    // 解析URL类型
    if isMv {
        // 处理MV
        handleSingleMV(urlRaw)
    } else if isPlaylist {
        // 处理播放列表
        task.DoPlayList(playlistId, storefront, urlRaw)
    } else if isStation {
        // 处理电台
        task.DoStation(stationId, storefront, urlRaw)
    } else {
        // 处理专辑/单曲
        err = downloader.Rip(albumId, storefront, urlArg_i, urlRaw)
    }
    
    if isBatch {
        if err != nil {
            core.SafePrintf("❌ [%d/%d] 任务失败: %s\n", currentTask, totalTasks, urlRaw)
        } else {
            core.SafePrintf("✅ [%d/%d] 任务完成: %s\n", currentTask, totalTasks, urlRaw)
        }
    }
    
    return albumId, albumName, err
}
```

**状态**：✅ **完全符合**
- 显示当前进度 [X/Y]
- 处理各种类型的链接
- 完成后显示结果

### 9. 专辑下载（downloader.Rip）

```go
// downloader.Rip 函数流程：
1. 检查文件是否已存在（第776-853行）
   - 全部存在 → 跳过下载，直接返回
   - 部分存在 → 只下载不存在的

2. 批次下载循环（第853-1129行）
   - 每批歌曲并发下载（配置文件控制线程数）
   - 下载到缓存路径
   - 完成加工（FFmpeg、标签）
   
3. 批次完成后转移文件（第1078-1127行）
   - 多批次且不是最后一批 → 立即转移
   - 检查目标文件存在性
   - 只转移新文件，不覆盖已有文件
   
4. 所有批次完成后最终转移（第1150-1215行）
   - 递归扫描缓存
   - 转移所有剩余文件
   - 检查并跳过已存在文件
   - 显示统计：「新增 X 个，跳过 Y 个」
   
5. 清理缓存（第1217-1220行）
   - 删除缓存hash目录
```

**状态**：✅ **完全符合**
- 下载到缓存
- 完成加工
- 转移文件
- 清理缓存

### 10. 保存历史记录（第400-407行）

```go
// 保存任务历史
if task != nil {
    if err := history.SaveTask(task); err != nil {
        core.SafePrintf("\n⚠️  保存历史记录失败: %v\n", err)
    } else {
        core.SafePrintf("\n📜 历史记录已保存至: history/%s.json\n", task.TaskID)
    }
}
```

**状态**：✅ **完全符合**

## 📊 完整工作流程验证

### 流程图

```
┌─────────────────────────────────────────────────────────────┐
│ 1. 读取 TXT 文件 (parseTxtFile)                              │
│    - 解析每一行                                               │
│    - 支持空格分隔多链接                                       │
│    - 跳过空行和注释                                          │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. 清点链接数                                                │
│    📋 初始链接总数: 63                                       │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. 预处理链接（展开歌手页面等）                              │
│    🔄 开始预处理链接...                                      │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. 历史记录过滤                                              │
│    📜 历史记录检测: 发现 5 个已完成的任务                    │
│    ⏭️  已自动跳过，剩余 58 个任务                            │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. 显示任务统计                                              │
│    📋 ========== 开始下载任务 ==========                     │
│    📝 任务总数: 58                                           │
│    ⚡ 执行模式: 串行模式                                      │
│    📦 专辑内并发: 由配置文件控制                             │
│    📜 历史记录: 已启用                                       │
│    ====================================                      │
└────────────────────────┬────────────────────────────────────┘
                         ↓
          ┌──────────────┴──────────────┐
          │  串行下载循环（for i, url） │
          └──────────────┬──────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. 处理第 1 个链接                                           │
│    🧾 [1/58] 开始处理: https://...                          │
│    ├─ 解析URL类型                                            │
│    ├─ 调用 downloader.Rip                                    │
│    │  ├─ 检查文件是否已存在                                  │
│    │  ├─ 下载到缓存（专辑内并发）                            │
│    │  ├─ 完成加工（FFmpeg、标签）                            │
│    │  ├─ 批次完成后转移文件                                  │
│    │  ├─ 最终转移剩余文件                                    │
│    │  │  📥 文件转移完成！（新增 36 个，跳过 0 个）          │
│    │  └─ 清理缓存                                            │
│    ├─ 记录历史                                               │
│    └─ ✅ [1/58] 任务完成                                     │
│                                                              │
│    ════════════════════════════════════════                 │
│                                                              │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. 处理第 2 个链接                                           │
│    🧾 [2/58] 开始处理: https://...                          │
│    ├─ ... (同上) ...                                         │
│    └─ ✅ [2/58] 任务完成                                     │
│                                                              │
│    ════════════════════════════════════════                 │
└────────────────────────┬────────────────────────────────────┘
                         ↓
                        ...
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. 处理第 58 个链接（最后一个）                              │
│    🧾 [58/58] 开始处理: https://...                         │
│    ├─ ... (同上) ...                                         │
│    └─ ✅ [58/58] 任务完成                                    │
│    （最后一个任务不显示分隔线）                              │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. 保存历史记录                                              │
│    📜 历史记录已保存至: history/xxx.json                     │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 10. 显示统计                                                 │
│     📦 已完成: 58/58 | 警告: 0 | 错误: 0                    │
└─────────────────────────────────────────────────────────────┘
```

## ✅ 验证结果

### 期望流程 vs 实际实现

| 步骤 | 期望 | 实际实现 | 状态 |
|------|------|----------|------|
| 1. 读取 txt 文件 | ✅ | parseTxtFile (第228-252行) | ✅ **完全符合** |
| 2. 清点链接数 | ✅ | 显示初始链接总数 (第258-261行) | ✅ **完全符合** |
| 3. 依次读取链接 | ✅ | 串行 for 循环 (第371行) | ✅ **完全符合** |
| 4. 串行下载 | ✅ | 无并发，逐个处理 (第371-397行) | ✅ **完全符合** |
| 5. 完成下载 | ✅ | processURL → Rip → 下载 | ✅ **完全符合** |
| 6. 移动文件 | ✅ | 批次转移 + 最终转移 | ✅ **完全符合** |
| 7. 继续下一个 | ✅ | for 循环自动继续 | ✅ **完全符合** |

### 额外的增强功能

| 功能 | 描述 | 位置 |
|------|------|------|
| **历史记录** | 自动跳过已完成任务 | 第305-350行 |
| **预处理** | 展开歌手页面为专辑列表 | 第263-296行 |
| **进度显示** | [X/Y] 显示当前进度 | processURL |
| **视觉分隔** | 任务之间80个等号分隔 | 第393-397行 |
| **统计反馈** | 转移文件时显示新增/跳过数量 | downloader.Rip |
| **增量下载** | 只下载不存在的文件 | downloader.Rip |
| **智能跳过** | 检查目标文件存在性，不覆盖 | SafeMoveFile |

## 🎯 关键特性

### 1. 真正的串行执行

```go
// 第371行：for i, urlToProcess := range finalUrls
```
- ✅ 使用顺序 for 循环，不是 goroutine
- ✅ 每个任务完全完成后才开始下一个
- ✅ 文件转移在任务内部完成

### 2. 文件转移时机

**时机1：批次转移**（专辑内多批次时）
```
批次1完成 → 转移批次1文件 → 批次2下载 → 转移批次2文件
```

**时机2：最终转移**（专辑完成时）
```
所有批次完成 → 转移所有剩余文件 → 清理缓存
```

**结果**：
- ✅ 每个专辑下载完成后，文件立即转移到目标位置
- ✅ 清理缓存，不留残留
- ✅ 然后 for 循环自动进入下一个链接

### 3. 不覆盖已有文件

```go
// SafeMoveFile (helpers.go 第172-177行)
targetExists, _ := FileExists(dst)
if targetExists {
    return fmt.Errorf("目标文件已存在，跳过")
}
```
- ✅ 转移前检查目标文件
- ✅ 已存在则跳过
- ✅ 真正的增量下载

## 📝 实际运行示例

```bash
$ ./apple-music-downloader albums.txt

================================================================================
🎵 Apple Music Downloader v2.5.2 (experiment/improve-txt-batch-tasks)
📅 编译时间: 2025-10-10 13:11:33 CST
🔖 Git提交: ee0cc1e
================================================================================

📋 初始链接总数: 63
🔄 开始预处理链接...

📜 历史记录检测: 发现 5 个已完成的任务
⏭️  已自动跳过，剩余 58 个任务

📋 ========== 开始下载任务 ==========
📝 任务总数: 58
⚡ 执行模式: 串行模式 
📦 专辑内并发: 由配置文件控制
📜 历史记录: 已启用
====================================

🧾 [1/58] 开始处理: https://music.apple.com/cn/album/...
🎤 歌手: 马友友
💽 专辑: Six Evolutions - Bach: Cello Suites
🔬 正在进行版权预检，请稍候...
📡 音源: Hi-Res Lossless | 5 线程 | CN | 1 个账户并行下载
--------------------------------------------------
Track 1 of 36: ... - 下载完成
Track 2 of 36: ... - 下载完成
...
Track 36 of 36: ... - 下载完成
--------------------------------------------------

📤 正在从缓存转移文件到目标位置...
📥 文件转移完成！（新增 36 个，跳过 0 个）

✅ [1/58] 任务完成: https://music.apple.com/cn/album/...

================================================================================

🧾 [2/58] 开始处理: https://music.apple.com/cn/album/...
...
✅ [2/58] 任务完成: https://music.apple.com/cn/album/...

================================================================================

...

🧾 [58/58] 开始处理: https://music.apple.com/cn/album/...
...
✅ [58/58] 任务完成: https://music.apple.com/cn/album/...

📜 历史记录已保存至: history/albums-20251010-130000.json

📦 已完成: 58/58 | 警告: 0 | 错误: 0
```

## ✅ 最终结论

批量下载任务的工作流程**完全符合**用户期望：

1. ✅ **读取 txt 文件** - parseTxtFile 函数
2. ✅ **清点链接数** - 显示初始链接总数和最终任务数
3. ✅ **依次读取链接** - for 循环顺序遍历
4. ✅ **串行下载** - 无并发，逐个执行
5. ✅ **完成下载** - processURL → Rip 完整流程
6. ✅ **移动文件** - 批次转移 + 最终转移，检查不覆盖
7. ✅ **继续下一个** - for 循环自动进入下一次迭代

**额外优势**：
- ✅ 历史记录自动跳过已完成任务
- ✅ 增量下载，只下载不存在的文件
- ✅ 智能转移，不覆盖已有文件
- ✅ 清晰的进度显示和统计反馈

