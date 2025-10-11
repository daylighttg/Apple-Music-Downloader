# 构建脚本使用示例

本文档提供常见构建场景的实用示例。

---

## 📝 **基础示例**

### **1. 快速构建（开发）**

```bash
# 构建开发版本
./build-quick.sh

# 构建带版本号
./build-quick.sh v2.6.1-dev

# 运行
./apple-music-downloader --help
```

### **2. 发布构建（所有平台）**

```bash
# 构建发布版本
./build-release.sh v2.6.0

# 查看输出
ls -lh build/
ls -lh dist/
```

---

## 🎯 **实际场景**

### **场景1: 日常开发测试**

```bash
# 1. 修改代码
vim main.go

# 2. 快速构建
./build-quick.sh dev

# 3. 测试
./apple-music-downloader --help
```

### **场景2: 发布新版本**

```bash
# 1. 更新变更日志
vim CHANGELOG.md

# 2. 提交更改
git add CHANGELOG.md
git commit -m "docs: update changelog for v2.6.1"

# 3. 创建标签
git tag -a v2.6.1 -m "Release v2.6.1"

# 4. 推送标签
git push origin main
git push origin v2.6.1

# 5. 构建发布包
./build-release.sh v2.6.1

# 6. 验证构建
./build/apple-music-downloader-v2.6.1-linux-amd64 --help

# 7. 检查校验和
cat dist/checksums.txt
```

### **场景3: 仅构建特定平台**

```bash
# 手动构建单个平台
GOOS=darwin GOARCH=arm64 \
  go build -ldflags "-s -w -X 'main.Version=v2.6.0'" \
  -o apple-music-downloader-darwin-arm64 .
```

### **场景4: 测试跨平台构建**

```bash
# 构建所有平台
./build-release.sh v2.6.0

# 验证每个平台的二进制
for file in build/apple-music-downloader-*; do
    echo "Testing: $file"
    file "$file"
done
```

---

## 🔧 **高级用法**

### **自定义构建标志**

编辑 `build-release.sh`：

```bash
# 添加调试信息
LDFLAGS="-X 'main.Version=${VERSION}' -X 'main.BuildTime=${BUILD_TIME}'"

# 或保持调试符号（不使用 -s -w）
LDFLAGS="-X 'main.Version=${VERSION}'"
```

### **添加自定义变量**

在 `main.go` 中添加：

```go
package main

var (
    Version   string = "dev"
    BuildTime string = "unknown"
    GitCommit string = "unknown"
    CustomVar string = "default"
)
```

构建时注入：

```bash
go build -ldflags "-X 'main.CustomVar=production'" .
```

### **压缩二进制**

使用 UPX 进一步压缩：

```bash
# 安装 UPX
apt install upx  # Ubuntu
brew install upx # macOS

# 构建后压缩
./build-release.sh v2.6.0
upx --best build/apple-music-downloader-*
```

---

## 📦 **发布包验证**

### **验证压缩包完整性**

```bash
# Linux/macOS
tar -tzf dist/apple-music-downloader-v2.6.0-linux-amd64.tar.gz

# Windows (需要 zip 工具)
unzip -l dist/apple-music-downloader-v2.6.0-windows-amd64.zip
```

### **验证校验和**

```bash
# 方式1: 自动验证所有文件
cd dist/
sha256sum -c checksums.txt

# 方式2: 手动验证单个文件
sha256sum apple-music-downloader-v2.6.0-linux-amd64.tar.gz
grep linux-amd64 checksums.txt
```

### **测试解压后的包**

```bash
# 创建测试目录
mkdir test-release
cd test-release

# 解压
tar -xzf ../dist/apple-music-downloader-v2.6.0-linux-amd64.tar.gz

# 进入目录
cd apple-music-downloader-v2.6.0-linux-amd64/

# 测试运行
./apple-music-downloader-v2.6.0-linux-amd64 --help

# 检查文件
ls -la
cat QUICKSTART.txt
```

---

## 🚀 **GitHub Release 流程**

### **完整发布流程**

```bash
# 1. 确保在正确的分支
git checkout main
git pull origin main

# 2. 构建发布包
./build-release.sh v2.6.0

# 3. 创建release notes
cat > release-notes.md << 'EOF'
## What's New in v2.6.0

### Features
- Feature 1
- Feature 2

### Bug Fixes
- Fix 1
- Fix 2

### Download
See assets below.
EOF

# 4. 使用 GitHub CLI 创建 release
gh release create v2.6.0 \
  --title "Release v2.6.0" \
  --notes-file release-notes.md \
  dist/*.tar.gz \
  dist/*.zip \
  dist/checksums.txt

# 或手动上传到 GitHub Release 页面
```

### **使用 GitHub Actions 自动化**

创建 `.github/workflows/release.yml`：

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Build
        run: ./build-release.sh ${{ github.ref_name }}
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: dist/*
          generate_release_notes: true
```

---

## 🐛 **故障排除示例**

### **问题: 编译失败**

```bash
# 清理并重试
go clean -cache
go mod tidy
./build-quick.sh
```

### **问题: 跨平台编译失败**

```bash
# 测试单个平台
GOOS=windows GOARCH=amd64 go build -o test.exe .

# 如果成功，运行完整构建
./build-release.sh v2.6.0
```

### **问题: 二进制文件过大**

```bash
# 检查当前大小
ls -lh build/

# 确保使用了压缩标志
go build -ldflags "-s -w" -o test .

# 或使用 UPX
upx --best test
```

### **问题: 版本信息未注入**

```bash
# 检查版本信息
./apple-music-downloader --version

# 手动构建并注入
go build -ldflags "-X 'main.Version=v2.6.0'" .
./apple-music-downloader --version
```

---

## 📊 **性能对比**

### **构建时间对比**

```bash
# 快速构建（单平台）
time ./build-quick.sh v2.6.0
# 预期: ~10-30秒

# 发布构建（6个平台）
time ./build-release.sh v2.6.0
# 预期: ~1-3分钟
```

### **文件大小对比**

```bash
# 未压缩
go build -o test-uncompressed .
ls -lh test-uncompressed

# 使用 -ldflags "-s -w"
go build -ldflags "-s -w" -o test-compressed .
ls -lh test-compressed

# 使用 UPX
upx --best test-compressed -o test-upx
ls -lh test-upx
```

---

## 🔄 **持续集成**

### **本地 CI 模拟**

```bash
#!/bin/bash
# local-ci.sh - 模拟 CI 流程

echo "=== Step 1: 代码检查 ==="
go fmt ./...
go vet ./...

echo "=== Step 2: 运行测试 ==="
go test ./...

echo "=== Step 3: 构建 ==="
./build-release.sh v2.6.0-ci

echo "=== Step 4: 验证 ==="
./build/apple-music-downloader-*-linux-amd64 --help

echo "=== CI 完成 ==="
```

### **GitLab CI 示例**

```yaml
# .gitlab-ci.yml
stages:
  - build
  - release

build:
  stage: build
  image: golang:1.21
  script:
    - ./build-release.sh $CI_COMMIT_TAG
  artifacts:
    paths:
      - dist/
  only:
    - tags

release:
  stage: release
  script:
    - echo "Creating release..."
  only:
    - tags
```

---

## 💡 **最佳实践**

1. **版本号规范**
   ```bash
   # 主版本.次版本.修订号
   v2.6.0      # 正式版本
   v2.6.1-rc1  # 候选版本
   v2.6.1-dev  # 开发版本
   ```

2. **构建前检查**
   ```bash
   # 确保代码干净
   git status
   
   # 确保测试通过
   go test ./...
   
   # 确保没有格式问题
   go fmt ./...
   ```

3. **发布后验证**
   ```bash
   # 下载并测试发布包
   wget https://github.com/user/repo/releases/download/v2.6.0/...
   tar -xzf ...
   ./apple-music-downloader --help
   ```

---

**提示**: 更多详细信息请参考 `BUILD.md`

