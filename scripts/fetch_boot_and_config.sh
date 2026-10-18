#!/usr/bin/env bash
set -euo pipefail

mkdir -p prebuilt repack configs

RAW_INPUT="${BOOT_URL}"
CLEAN_URL=$(echo "$RAW_INPUT" | grep -oE 'https?://[^])" >]+' | head -n 1 || true)
[ -z "$CLEAN_URL" ] && CLEAN_URL="$RAW_INPUT"

if [[ "$CLEAN_URL" == *"sourceforge.net/projects/"* ]]; then
  CLEAN_URL=$(echo "$CLEAN_URL" | sed -E -e 's|/download/?$||' -e 's|sourceforge\.net/projects/|downloads.sourceforge.net/project/|' -e 's|/files/|/|')
fi

echo "=== Downloading Stock boot.img ==="
echo "URL: $CLEAN_URL"

curl -LSs -f -o prebuilt/boot.img "$CLEAN_URL" || \
curl -LSs -f -o prebuilt/boot.img "${CLEAN_URL}?use_mirror=autoselect" || \
curl -LSs -f -o prebuilt/boot.img "${RAW_INPUT}"

file prebuilt/boot.img | grep -qiE "HTML|ASCII text" && { echo "::error::下载的文件不是有效的 boot.img 二进制文件！"; exit 1; }

echo "=== Unpacking boot.img ==="
cp prebuilt/boot.img repack/
cd repack
magiskboot unpack boot.img

KERNEL_BANNER=$(strings kernel | grep -m 1 -E "Linux version 5\.15\.[0-9]+" || true)
echo "Stock Banner: ${KERNEL_BANNER}"

STOCK_UTS=$(echo "$KERNEL_BANNER" | sed -E -n 's/.*Linux version ([^ ]+).*/\1/p' | head -n 1 || true)
DETECTED_SHA=$(echo "$STOCK_UTS" | grep -oE -- '-g[0-9a-f]+' | head -n 1 | sed 's/-g//' || true)
SCM_SUFFIX=$(echo "$STOCK_UTS" | sed -E 's/^5\.15\.[0-9]+//' || true)

echo "BOOT_URL=${CLEAN_URL}" >> "${GITHUB_ENV}"
echo "KERNEL_BANNER=${KERNEL_BANNER}" >> "${GITHUB_ENV}"
echo "STOCK_UTS=${STOCK_UTS}" >> "${GITHUB_ENV}"
echo "DETECTED_SHA=${DETECTED_SHA}" >> "${GITHUB_ENV}"
echo "SCM_SUFFIX=${SCM_SUFFIX}" >> "${GITHUB_ENV}"
echo "CR_BRANCH=${CR_BRANCH}" >> "${GITHUB_ENV}"
echo "CR_VER=${CR_VER}" >> "${GITHUB_ENV}"
echo "ANDROID_VER=${ANDROID_VER}" >> "${GITHUB_ENV}"

echo "Target Version: crDroid ${CR_VER} (${ANDROID_VER}) -> Branch ${CR_BRANCH}"

echo "=== Extracting embedded IKCONFIG from kernel ==="
OUT_CONFIG="${GITHUB_WORKSPACE}/configs/stock.config"

# 查找 IKCFG_ST 标识符并解压缩 gzip 流 (纯 Shell 实现，免去 Python 依赖)
POS=$(grep -b -a -o -m 1 "IKCFG_ST" kernel | head -n 1 | cut -d: -f1 || true)
if [ -n "$POS" ]; then
  tail -c "+$((POS + 9))" kernel | gzip -dc > "$OUT_CONFIG" 2>/dev/null || true
fi

# 备用方案：tr 过滤提取 (标准 Linux 内核 extract-ikconfig 实现)
if [ ! -s "$OUT_CONFIG" ]; then
  CF1='IKCFG_ST\037\213\010'
  CF2='0123456789'
  POS=$(tr "$CF1\n$CF2" "\n$CF2=" < kernel | grep -abo "^$CF2" | head -n 1 || true)
  if [ -n "$POS" ]; then
    POS=${POS%%:*}
    tail -c "+$((POS + 9))" kernel | zcat > "$OUT_CONFIG" 2>/dev/null || true
  fi
fi

[ -s "$OUT_CONFIG" ] || { echo "::error::无法从官方 boot.img 提取内核 .config！"; exit 1; }
echo "Successfully extracted $(wc -l < "$OUT_CONFIG") lines of stock config."
