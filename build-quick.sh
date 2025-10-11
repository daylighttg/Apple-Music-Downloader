#!/bin/bash

# 快速构建脚本 - 仅构建当前平台

set -e

VERSION=${1:-"dev"}
OUTPUT_NAME="apple-music-downloader"

echo "🔨 快速构建 ${VERSION}..."

# 编译当前平台
go build -ldflags "-s -w -X 'main.Version=${VERSION}'" -o "${OUTPUT_NAME}" .

FILE_SIZE=$(du -h "${OUTPUT_NAME}" | cut -f1)

echo "✅ 构建完成: ${OUTPUT_NAME} (${FILE_SIZE})"
echo ""
echo "运行: ./${OUTPUT_NAME} --help"

