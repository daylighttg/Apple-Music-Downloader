# 构建指南

本文档说明如何构建 Apple Music Downloader 的二进制文件。

---

## 📋 **前置要求**

- **Go**: 1.19 或更高版本
- **Git**: 用于获取版本信息
- **tar**: Linux/macOS 打包（通常已预装）
- **zip**: Windows 打包（通常已预装）

---

## 🚀 **快速构建**

用于日常开发，仅构建当前平台的二进制文件：

```bash
# 使用默认版本 (dev)
./build-quick.sh

# 指定版本号
./build-quick.sh v2.6.0

# 输出
apple-music-downloader (当前平台)
```

---

## 📦 **发布构建**

用于正式发布，构建所有支持平台的二进制文件和发布包：

```bash
# 使用默认版本 (v2.6.0)
./build-release.sh

# 指定版本号
./build-release.sh v2.7.0
```

### **构建输出**

#### **二进制文件** (`build/`)

```
apple-music-downloader-v2.6.0-linux-amd64
apple-music-downloader-v2.6.0-linux-arm64
apple-music-downloader-v2.6.0-darwin-amd64
apple-music-downloader-v2.6.0-darwin-arm64
apple-music-downloader-v2.6.0-windows-amd64.exe
apple-music-downloader-v2.6.0-windows-arm64.exe
```

#### **发布包** (`dist/`)

```
apple-music-downloader-v2.6.0-linux-amd64.tar.gz
apple-music-downloader-v2.6.0-linux-arm64.tar.gz
apple-music-downloader-v2.6.0-darwin-amd64.tar.gz
apple-music-downloader-v2.6.0-darwin-arm64.tar.gz
apple-music-downloader-v2.6.0-windows-amd64.zip
apple-music-downloader-v2.6.0-windows-arm64.zip
checksums.txt
```

#### **发布包内容**

每个发布包包含：

- 二进制文件
- `config.yaml.example` - 配置文件示例
- `README.md` - 英文说明
- `README-CN.md` - 中文说明
- `CHANGELOG.md` - 变更日志
- `FEATURES.md` - 功能列表
- `QUICKSTART.txt` - 快速开始指南

---

## 🎯 **支持的平台**

| 操作系统 | 架构 | 包格式 |
|---------|------|--------|
| Linux | amd64 | .tar.gz |
| Linux | arm64 | .tar.gz |
| macOS | amd64 (Intel) | .tar.gz |
| macOS | arm64 (Apple Silicon) | .tar.gz |
| Windows | amd64 | .zip |
| Windows | arm64 | .zip |

---

## 🔧 **编译选项**

### **LDFLAGS**

脚本使用以下编译标志：

```bash
-s -w                           # 减小二进制大小
-X 'main.Version=${VERSION}'    # 注入版本号
-X 'main.BuildTime=${TIME}'     # 注入构建时间
-X 'main.GitCommit=${COMMIT}'   # 注入Git提交哈希
```

### **CGO_ENABLED**

```bash
CGO_ENABLED=0  # 禁用CGO，生成静态链接二进制
```

### **构建模式**

```bash
-trimpath  # 移除构建路径，增强可重现性
```

---

## 📊 **预期文件大小**

| 平台 | 压缩后 | 解压后 |
|------|--------|--------|
| Linux amd64 | ~10 MB | ~27 MB |
| macOS amd64 | ~10 MB | ~28 MB |
| Windows amd64 | ~10 MB | ~27 MB |

*注：实际大小可能因版本和编译器而异*

---

## 🔐 **校验和验证**

构建脚本会自动生成 `checksums.txt` 文件：

```bash
# 验证下载的文件
sha256sum -c checksums.txt

# 或单独验证
sha256sum apple-music-downloader-v2.6.0-linux-amd64.tar.gz
```

---

## 🚀 **发布流程**

### **1. 准备发布**

```bash
# 确保在 main 分支
git checkout main

# 确保代码是最新的
git pull origin main

# 检查工作目录干净
git status
```

### **2. 更新版本信息**

- 更新 `CHANGELOG.md`
- 更新 `VERSION` 文件（如果有）
- 提交更改

```bash
git add CHANGELOG.md VERSION
git commit -m "chore: bump version to v2.6.0"
```

### **3. 创建Git标签**

```bash
git tag -a v2.6.0 -m "Release v2.6.0"
git push origin main
git push origin v2.6.0
```

### **4. 构建发布包**

```bash
./build-release.sh v2.6.0
```

### **5. 验证构建**

```bash
# 测试二进制
./build/apple-music-downloader-v2.6.0-linux-amd64 --help

# 验证压缩包
tar -tzf dist/apple-music-downloader-v2.6.0-linux-amd64.tar.gz

# 检查校验和
cat dist/checksums.txt
```

### **6. 创建GitHub Release**

1. 前往 GitHub 仓库的 Releases 页面
2. 点击 "Draft a new release"
3. 选择标签 `v2.6.0`
4. 填写发布说明（从 `CHANGELOG.md` 复制）
5. 上传 `dist/` 目录下的所有文件：
   - 所有 `.tar.gz` 文件
   - 所有 `.zip` 文件
   - `checksums.txt`
6. 发布 Release

---

## 🐛 **故障排除**

### **问题：找不到 Go 命令**

```bash
# 检查Go是否安装
which go

# 安装Go（Ubuntu/Debian）
sudo apt install golang-go

# 安装Go（macOS）
brew install go
```

### **问题：编译失败**

```bash
# 清理缓存
go clean -cache

# 更新依赖
go mod tidy
go mod download

# 重新构建
./build-release.sh
```

### **问题：权限被拒绝**

```bash
# 添加执行权限
chmod +x build-release.sh build-quick.sh
```

### **问题：跨平台编译失败**

某些平台可能需要额外的工具链：

```bash
# 安装交叉编译工具（如果需要）
# 通常 Go 自带跨平台编译支持，无需额外安装
```

---

## 📝 **自定义构建**

### **添加新平台**

编辑 `build-release.sh`，在 `PLATFORMS` 数组中添加：

```bash
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "linux/riscv64"  # 新增平台
    # ...
)
```

### **修改编译标志**

编辑 `build-release.sh`，修改 `LDFLAGS` 变量：

```bash
LDFLAGS="-s -w -X 'main.CustomVar=value'"
```

### **更改输出目录**

```bash
BUILD_DIR="./custom-build"
DIST_DIR="./custom-dist"
```

---

## 🔄 **CI/CD 集成**

### **GitHub Actions 示例**

```yaml
name: Build Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Build
        run: ./build-release.sh ${{ github.ref_name }}
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: release-packages
          path: dist/*
```

---

## 📚 **参考资料**

- [Go编译选项文档](https://pkg.go.dev/cmd/go)
- [跨平台编译指南](https://go.dev/doc/install/source#environment)
- [GitHub Releases文档](https://docs.github.com/en/repositories/releasing-projects-on-github)

---

## ✨ **最佳实践**

1. **版本号规范**: 遵循 [语义化版本](https://semver.org/lang/zh-CN/)
2. **构建标签**: 始终使用Git标签触发发布构建
3. **测试优先**: 在发布前测试所有平台的二进制文件
4. **校验和**: 始终提供校验和文件供用户验证
5. **发布说明**: 详细记录每个版本的变更和修复

---

**最后更新**: 2025-10-11

