#!/usr/bin/env bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}/release_dist"

BUILD_DATE=$(date +'%Y%m%d')

# 清理元数据临时文件
rm -f metadata*.env

# 生成合并后的校验哈希
sha256sum *.img *.zip > sha256.txt
echo "Output files ready for release:"
ls -la

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
### 规格信息
- **适用设备**: 一加 Ace 3 / 一加 12R (\`astonc\` / \`aston\`)
$(if [[ "${BUILT_VERSIONS}" == *"12"* ]] && [[ "${BUILT_VERSIONS}" == *"13"* ]]; then
    echo "- **包含系统**: crDroid 12.0 (Android 16) & crDroid 13.0 (Android 17)"
  elif [[ "${BUILT_VERSIONS}" == *"13"* ]]; then
    echo "- **包含系统**: crDroid 13.0 (Android 17)"
  else
    echo "- **包含系统**: crDroid 12.0 (Android 16)"
  fi)
- **构建方案**: ${KSU_CHOICE}
- **编译器**: AOSP Clang r563880c (Clang 21.0.0)
- **构建日期**: ${BUILD_DATE}

### 产物格式说明
- **\`.img\` (Boot 镜像)**: 官方底包重封装镜像，适用于电脑端 Fastboot 线刷（请根据文件名区分 16.0 与 17.0）。
- **\`-AK3.zip\` (AnyKernel3 卡刷包)**: 原地替换内核并保留系统 ramdisk 与引导参数，推荐在 Recovery 模式下卡刷。

### 版本标识说明
- **\`crdroid-17.0-...\`**: 适配 **crDroid 13 (Android 17)** 底包
- **\`crdroid-16.0-...\`**: 适配 **crDroid 12 (Android 16)** 底包
- **\`ksu-next\`**: 集成 KernelSU-Next 分支
- **\`ksu\`**: 集成 KernelSU 官方稳定分支
- **\`stock\`**: 原生未 Root 纯净内核

### 刷入说明
- **Recovery 卡刷 (推荐)**: 手机进入 Recovery 模式 -> \`adb sideload <对应的 AK3.zip>\`
- **Fastboot 线刷**: \`fastboot flash boot <对应的 boot.img>\`
EOF

echo "Creating GitHub Release: ${TAG_NAME} (${RELEASE_TITLE})"
gh release create "${TAG_NAME}" \
  crdroid-* sha256.txt \
  --repo "${GITHUB_REPOSITORY}" \
  --title "${RELEASE_TITLE}" \
  --notes-file release_notes.md || \
gh release upload "${TAG_NAME}" crdroid-* sha256.txt --repo "${GITHUB_REPOSITORY}" --clobber
