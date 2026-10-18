#!/usr/bin/env bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}/release_dist"

BUILD_DATE=$(date +'%Y%m%d')

echo "=== [1/4] Generating SHA-256 Checksums ==="
sha256sum *.img *.zip > sha256.txt
echo "Output files ready for release:"
ls -lh

echo "=== [2/4] Parsing Metadata from Matrix Jobs ==="
PROCESSED_BRANCHES=()
METADATA_SECTION=""

for env_file in metadata_*.env; do
  [ -f "$env_file" ] || continue

  # 加载元数据环境变量
  unset CR_BRANCH CR_VER ANDROID_VER SUBLEVEL SHORT_SHA FINAL_SHA MODULES_SHA MODULES_SHORT_SHA BOOT_URL KERNEL_BANNER STOCK_UTS DETECTED_SHA KSU_TAG KSU_LABEL IMG_NAME AK3_NAME
  # shellcheck source=/dev/null
  . "$env_file"

  # 检查当前分支是否已经记录
  branch_seen=false
  for b in "${PROCESSED_BRANCHES[@]:-}"; do
    if [ "$b" = "${CR_BRANCH:-}" ]; then
      branch_seen=true
      break
    fi
  done

  if [ "$branch_seen" = false ] && [ -n "${CR_BRANCH:-}" ]; then
    PROCESSED_BRANCHES+=("${CR_BRANCH}")

    METADATA_SECTION+=$'#### 🔹 crDroid '"${CR_VER} (${ANDROID_VER} - 源码分支 \`${CR_BRANCH}\`)"$'\n'
    if [ -n "${BOOT_URL:-}" ]; then
      METADATA_SECTION+=$'- **官方底包来源 URL**: '"${BOOT_URL}"$'\n'
    fi
    if [ -n "${KERNEL_BANNER:-}" ]; then
      METADATA_SECTION+=$'- **底包内核提取标识 (Banner)**: `'"${KERNEL_BANNER}"$'`\n'
    elif [ -n "${STOCK_UTS:-}" ]; then
      METADATA_SECTION+=$'- **底包内核标识 (UTS)**: `'"${STOCK_UTS}"$'`\n'
    fi
    if [ -n "${DETECTED_SHA:-}" ]; then
      METADATA_SECTION+=$'- **底包识别 Commit Hash**: `'"${DETECTED_SHA}"$'`\n'
    fi
    if [ -n "${FINAL_SHA:-}" ]; then
      METADATA_SECTION+=$'- **内核源码编译 Commit**: [`crdroidandroid/android_kernel_oneplus_sm8550@'"${SHORT_SHA:-${FINAL_SHA:0:12}}"$'`](https://github.com/crdroidandroid/android_kernel_oneplus_sm8550/commit/'"${FINAL_SHA}"$')\n'
    fi
    if [ -n "${MODULES_SHA:-}" ]; then
      METADATA_SECTION+=$'- **外置驱动源码 Commit**: [`crdroidandroid/android_kernel_oneplus_sm8550-modules@'"${MODULES_SHORT_SHA:-${MODULES_SHA:0:12}}"$'`](https://github.com/crdroidandroid/android_kernel_oneplus_sm8550-modules/commit/'"${MODULES_SHA}"$')\n'
    fi
    if [ -n "${SUBLEVEL:-}" ]; then
      METADATA_SECTION+=$'- **Linux 内核基准版本**: `Linux 5.15.'"${SUBLEVEL}"$' (GKI 2.0+)`\n'
    fi
    METADATA_SECTION+=$'\n'
  fi
done

# 生成产物表格
CHECKSUM_TABLE=$'| 产物文件名称 | 格式类型 | 文件大小 | SHA-256 校验码 |\n| :--- | :---: | :---: | :--- |\n'

for f in *.img *.zip; do
  [ -f "$f" ] || continue
  sha=$(sha256sum "$f" | awk '{print $1}')
  size=$(ls -lh "$f" | awk '{print $5}')
  if [[ "$f" == *".img" ]]; then
    ftype="Fastboot Boot 镜像"
  elif [[ "$f" == *"AnyKernel3"* ]]; then
    ftype="Recovery 卡刷包"
  else
    ftype="压缩包"
  fi
  CHECKSUM_TABLE+=$'| `'${f}'` | '"${ftype}"' | `'"${size}"'` | `'"${sha}"'` |\n'
done

# 清理元数据临时文件
rm -f metadata*.env

echo "=== [3/4] Generating Release Notes ==="
# 根据构建的版本生成统一的 Tag 和标题
if [[ "${BUILT_VERSIONS}" == *"12"* ]] && [[ "${BUILT_VERSIONS}" == *"13"* ]]; then
  TAG_NAME="v12-v13-${KSU_CHOICE}-${BUILD_DATE}"
  RELEASE_TITLE="crDroid 12.0 & 13.0 (Android 16 & 17) - ${KSU_CHOICE}"
elif [[ "${BUILT_VERSIONS}" == *"13"* ]]; then
  TAG_NAME="v17.0-${KSU_CHOICE}-${BUILD_DATE}"
  RELEASE_TITLE="crDroid 13.0 (Android 17) - ${KSU_CHOICE}"
else
  TAG_NAME="v16.0-${KSU_CHOICE}-${BUILD_DATE}"
  RELEASE_TITLE="crDroid 12.0 (Android 16) - ${KSU_CHOICE}"
fi

cat << EOF > release_notes.md
### 📱 规格与基础信息
- **适用机型**: 一加 Ace 3 / 一加 12R (\`astonc\` / \`aston\`)
- **包含系统版本**: $(if [[ "${BUILT_VERSIONS}" == *"12"* ]] && [[ "${BUILT_VERSIONS}" == *"13"* ]]; then
    echo "crDroid 12.0 (Android 16) & crDroid 13.0 (Android 17)"
  elif [[ "${BUILT_VERSIONS}" == *"13"* ]]; then
    echo "crDroid 13.0 (Android 17)"
  else
    echo "crDroid 12.0 (Android 16)"
  fi)
- **Root 方案**: ${KSU_CHOICE}
- **编译工具链**: AOSP Clang r563880c (LLVM 21.0.0 Native Build)
- **构建日期**: ${BUILD_DATE}

---

### 📋 底包版本与 Commit Hash 详细对齐信息
${METADATA_SECTION}

---

### 📦 产物清单与文件校验 (Artifacts & Checksums)
${CHECKSUM_TABLE}

---

### 📲 刷入教程说明
- **Recovery 卡刷 (强烈推荐 🌟)**:
  手机进入 Recovery 模式 -> \`Apply update\` -> \`Apply from ADB\`，电脑终端执行：
  \`\`\`bash
  adb sideload <对应的 AnyKernel3 卡刷包.zip>
  \`\`\`
- **Fastboot 线刷**:
  手机进入 Bootloader 模式，电脑终端执行：
  \`\`\`bash
  fastboot flash boot <对应的 boot.img>
  fastboot reboot
  \`\`\`
- **无损卸载 Root / 一键救砖**:
  刷入对应系统版本的 \`-stock-*\` 镜像或卡刷包即可秒级还原为纯净原厂状态。
EOF

echo "=== [4/4] Publishing Release via GitHub CLI ==="
echo "Tag: ${TAG_NAME}"
echo "Title: ${RELEASE_TITLE}"

gh release create "${TAG_NAME}" \
  crdroid-* sha256.txt \
  --repo "${GITHUB_REPOSITORY}" \
  --title "${RELEASE_TITLE}" \
  --notes-file release_notes.md || \
gh release upload "${TAG_NAME}" crdroid-* sha256.txt --repo "${GITHUB_REPOSITORY}" --clobber
