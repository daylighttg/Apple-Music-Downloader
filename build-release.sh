#!/bin/bash

# Apple Music Downloader 二进制打包脚本
# 用于构建多平台发布版本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 版本信息
VERSION=${1:-"v2.6.0"}
BUILD_TIME=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# 构建目录
BUILD_DIR="./build"
DIST_DIR="./dist"
RELEASE_NAME="apple-music-downloader-${VERSION}"

# 编译标志
LDFLAGS="-s -w -X 'main.Version=${VERSION}' -X 'main.BuildTime=${BUILD_TIME}' -X 'main.GitCommit=${GIT_COMMIT}'"

# 支持的平台
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
    "windows/arm64"
)

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Apple Music Downloader - 二进制打包脚本${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}版本信息:${NC}"
echo -e "  版本号:     ${YELLOW}${VERSION}${NC}"
echo -e "  构建时间:   ${BUILD_TIME}"
echo -e "  Git提交:    ${GIT_COMMIT}"
echo -e "  Git分支:    ${GIT_BRANCH}"
echo ""

# 清理旧的构建文件
echo -e "${CYAN}📁 清理旧的构建文件...${NC}"
rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${BUILD_DIR}" "${DIST_DIR}"
echo -e "${GREEN}✅ 清理完成${NC}"
echo ""

# 检查依赖
echo -e "${CYAN}🔍 检查依赖...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${RED}❌ 未找到 Go 编译器${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Go 版本: $(go version)${NC}"
echo ""

# 编译各平台版本
echo -e "${CYAN}🔨 开始编译各平台版本...${NC}"
echo ""

for platform in "${PLATFORMS[@]}"; do
    IFS='/' read -r GOOS GOARCH <<< "$platform"
    
    # 文件名
    OUTPUT_NAME="apple-music-downloader-${VERSION}-${GOOS}-${GOARCH}"
    if [ "$GOOS" = "windows" ]; then
        OUTPUT_NAME="${OUTPUT_NAME}.exe"
    fi
    
    OUTPUT_PATH="${BUILD_DIR}/${OUTPUT_NAME}"
    
    echo -e "${BLUE}▶ 编译: ${GOOS}/${GOARCH}${NC}"
    
    # 编译
    if GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=0 \
        go build -trimpath -ldflags "${LDFLAGS}" -o "${OUTPUT_PATH}" .; then
        
        # 获取文件大小
        FILE_SIZE=$(du -h "${OUTPUT_PATH}" | cut -f1)
        echo -e "${GREEN}  ✅ 成功: ${OUTPUT_NAME} (${FILE_SIZE})${NC}"
    else
        echo -e "${RED}  ❌ 失败: ${GOOS}/${GOARCH}${NC}"
    fi
    echo ""
done

echo -e "${GREEN}✅ 所有平台编译完成${NC}"
echo ""

# 创建发布包
echo -e "${CYAN}📦 创建发布包...${NC}"
echo ""

for platform in "${PLATFORMS[@]}"; do
    IFS='/' read -r GOOS GOARCH <<< "$platform"
    
    # 文件名
    BINARY_NAME="apple-music-downloader-${VERSION}-${GOOS}-${GOARCH}"
    if [ "$GOOS" = "windows" ]; then
        BINARY_NAME="${BINARY_NAME}.exe"
    fi
    
    BINARY_PATH="${BUILD_DIR}/${BINARY_NAME}"
    
    # 检查二进制是否存在
    if [ ! -f "${BINARY_PATH}" ]; then
        continue
    fi
    
    # 创建发布目录
    RELEASE_DIR="${BUILD_DIR}/${RELEASE_NAME}-${GOOS}-${GOARCH}"
    mkdir -p "${RELEASE_DIR}"
    
    # 复制文件
    cp "${BINARY_PATH}" "${RELEASE_DIR}/"
    cp config.yaml.example "${RELEASE_DIR}/"
    cp README.md "${RELEASE_DIR}/"
    cp README-CN.md "${RELEASE_DIR}/"
    cp CHANGELOG.md "${RELEASE_DIR}/"
    cp FEATURES.md "${RELEASE_DIR}/"
    
    # 创建快速开始文档
    cat > "${RELEASE_DIR}/QUICKSTART.txt" << EOF
Apple Music Downloader ${VERSION}
================================

快速开始:

1. 配置文件:
   - 复制 config.yaml.example 为 config.yaml
   - 编辑 config.yaml，填入你的 media-user-token

2. 基本使用:
   - 交互模式: ./$(basename ${BINARY_PATH})
   - 单链接模式: ./$(basename ${BINARY_PATH}) "专辑URL"
   - 批量下载: ./$(basename ${BINARY_PATH}) urls.txt

3. 查看帮助:
   ./$(basename ${BINARY_PATH}) --help

4. 详细文档:
   请查看 README.md 和 CHANGELOG.md

================================
版本: ${VERSION}
构建时间: ${BUILD_TIME}
Git提交: ${GIT_COMMIT}
================================
EOF
    
    # 创建压缩包
    ARCHIVE_NAME="${RELEASE_NAME}-${GOOS}-${GOARCH}"
    
    if [ "$GOOS" = "windows" ]; then
        # Windows 使用 zip
        ARCHIVE_FILE="${DIST_DIR}/${ARCHIVE_NAME}.zip"
        echo -e "${BLUE}▶ 打包: ${ARCHIVE_NAME}.zip${NC}"
        (cd "${BUILD_DIR}" && zip -r -q "../${ARCHIVE_FILE}" "$(basename ${RELEASE_DIR})")
    else
        # Linux/macOS 使用 tar.gz
        ARCHIVE_FILE="${DIST_DIR}/${ARCHIVE_NAME}.tar.gz"
        echo -e "${BLUE}▶ 打包: ${ARCHIVE_NAME}.tar.gz${NC}"
        tar -czf "${ARCHIVE_FILE}" -C "${BUILD_DIR}" "$(basename ${RELEASE_DIR})"
    fi
    
    # 获取文件大小
    ARCHIVE_SIZE=$(du -h "${ARCHIVE_FILE}" | cut -f1)
    echo -e "${GREEN}  ✅ 成功: $(basename ${ARCHIVE_FILE}) (${ARCHIVE_SIZE})${NC}"
    
    # 清理临时目录
    rm -rf "${RELEASE_DIR}"
    
    echo ""
done

echo -e "${GREEN}✅ 所有发布包创建完成${NC}"
echo ""

# 生成校验和
echo -e "${CYAN}🔐 生成校验和文件...${NC}"
CHECKSUM_FILE="${DIST_DIR}/checksums.txt"

(cd "${DIST_DIR}" && sha256sum *.tar.gz *.zip 2>/dev/null > checksums.txt) || true

if [ -f "${CHECKSUM_FILE}" ]; then
    echo -e "${GREEN}✅ 校验和文件已生成: checksums.txt${NC}"
else
    echo -e "${YELLOW}⚠️  未生成校验和文件${NC}"
fi
echo ""

# 显示构建结果
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  构建结果${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${GREEN}二进制文件:${NC}"
ls -lh "${BUILD_DIR}"/apple-music-downloader-* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

echo -e "${GREEN}发布包:${NC}"
ls -lh "${DIST_DIR}"/*.{tar.gz,zip} 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

if [ -f "${CHECKSUM_FILE}" ]; then
    echo -e "${GREEN}校验和:${NC}"
    cat "${CHECKSUM_FILE}" | while read line; do
        echo "  $line"
    done
    echo ""
fi

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 打包完成！${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}发布文件位于: ${YELLOW}${DIST_DIR}/${NC}"
echo ""
echo -e "${CYAN}下一步:${NC}"
echo "  1. 验证二进制文件: ./build/apple-music-downloader-* --help"
echo "  2. 上传到 GitHub Release"
echo "  3. 更新发布说明"
echo ""

