# 🧪 验证新版本元数据修复

## 📅 时间线

| 时间 (UTC) | 事件 |
|-----------|------|
| **03:14:30** | 您下载的 Head Hunters 文件时间戳 |
| **03:48** | 新版本 `apple-music-downloader-v2.6.0-metadata-fix` 编译完成 |

**结论**: 您看到的文件是旧版本下载的，不是新版本！

---

## ✅ **验证新版本的正确方法**

### **步骤 1: 下载一个测试专辑**

```bash
# 使用新版本下载（选一个小专辑快速测试）
./apple-music-downloader-v2.6.0-metadata-fix "https://music.apple.com/cn/album/158571524"

# 或者下载单曲测试
./apple-music-downloader-v2.6.0-metadata-fix --song "https://music.apple.com/cn/album/158571524?i=158571528"
```

### **步骤 2: 检查新下载文件的元数据**

```bash
# 找到刚下载的文件
cd "下载目录"

# 检查元数据
exiftool "文件名.m4a" | grep -i album
```

### **步骤 3: 期望看到的结果**

```
Album                           : Head Hunters Hi-Res Lossless  ✅
Album Sort                      : Head Hunters Hi-Res Lossless  ✅
```

**如果看到上述结果，说明新版本修复成功！**

---

## 🔄 **更新旧文件的方法**

### **选项 1: 使用批量更新脚本**

```bash
# 更新您的音乐库
./update_album_metadata.sh "/Volumes/Music/AppleMusic/Alac"

# 脚本会自动：
# ✅ 扫描所有 .m4a 文件
# ✅ 从文件夹名提取音质标签
# ✅ 更新 Album 和 AlbumSort 字段
# ✅ 跳过已有标签的文件
```

### **选项 2: 重新下载**

```bash
# 删除旧文件
rm -rf "/Volumes/Music/AppleMusic/Alac/Herbie Hancock/Head Hunters Hi-Res Lossless"

# 用新版本重新下载
./apple-music-downloader-v2.6.0-metadata-fix "https://music.apple.com/cn/album/158571524"
```

---

## 🎯 **快速测试命令**

```bash
# 一键测试（下载一首歌并验证）
./apple-music-downloader-v2.6.0-metadata-fix --song "https://music.apple.com/cn/album/158571524?i=158571528" && \
exiftool "下载目录/*.m4a" | grep -E "Album|AlbumSort" | head -4
```

期望输出：
```
Album                           : Head Hunters Hi-Res Lossless
Album Sort                      : Head Hunters Hi-Res Lossless
```

---

## ❓ **FAQ**

### Q1: 为什么我的文件没有音质标签？

**A**: 您的文件是旧版本下载的（时间戳：03:14:30 UTC），而新版本在 03:48 UTC 才编译完成。

### Q2: 我需要重新下载所有音乐吗？

**A**: 不需要！使用 `update_album_metadata.sh` 脚本可以批量更新旧文件的元数据。

### Q3: 如何确认使用的是新版本？

**A**: 
```bash
# 检查文件修改时间
ls -lh apple-music-downloader-v2.6.0-metadata-fix
# 应该显示: Oct 11 11:48

# 或者用新版本下载一个测试文件，检查其元数据
```

### Q4: 批量更新脚本安全吗？

**A**: 安全！脚本：
- ✅ 使用 `-overwrite_original` 自动备份
- ✅ 只修改 Album 和 AlbumSort 字段
- ✅ 不影响其他元数据
- ✅ 跳过已有标签的文件

---

## 📝 **验证清单**

- [ ] 确认新版本编译时间（应为 Oct 11 11:48）
- [ ] 用新版本下载测试文件
- [ ] 检查测试文件的元数据
- [ ] 确认 Album 字段包含音质标签
- [ ] 使用批量脚本更新旧文件（可选）

---

**重点**: 您当前看到的文件是**旧版本下载的**，请用**新版本重新测试**！

