#!/usr/bin/env bash
set -euo pipefail

echo "Validating inputs and generating build matrix..."

URL_13="${BOOT_URL_13:-}"
URL_12="${BOOT_URL_12:-}"
COMMIT_13="${CUSTOM_COMMIT_13:-}"
COMMIT_12="${CUSTOM_COMMIT_12:-}"
KSU_CHOICE="${KSU_VARIANT:-All}"

# 解析 KSU 选项列表
KSU_LIST=()
if [ "$KSU_CHOICE" = "All" ]; then
  KSU_LIST=("KernelSU-Next" "KernelSU" "None (Pure Stock)")
else
  KSU_LIST=("$KSU_CHOICE")
fi

TARGETS=()

if [ -n "$URL_13" ]; then
  echo "Target crDroid 13 (Android 17) enabled."
  for ksu in "${KSU_LIST[@]}"; do
    ENTRY=$(jq -n \
      --arg version "13" \
      --arg cr_ver "13.0" \
      --arg cr_branch "17.0" \
      --arg android_ver "Android 17" \
      --arg boot_url "$URL_13" \
      --arg custom_commit "$COMMIT_13" \
      --arg ksu_variant "$ksu" \
      '{version: $version, cr_ver: $cr_ver, cr_branch: $cr_branch, android_ver: $android_ver, boot_url: $boot_url, custom_commit: $custom_commit, ksu_variant: $ksu_variant}')
    TARGETS+=("$ENTRY")
  done
fi

if [ -n "$URL_12" ]; then
  echo "Target crDroid 12 (Android 16) enabled."
  for ksu in "${KSU_LIST[@]}"; do
    ENTRY=$(jq -n \
      --arg version "12" \
      --arg cr_ver "12.0" \
      --arg cr_branch "16.0" \
      --arg android_ver "Android 16" \
      --arg boot_url "$URL_12" \
      --arg custom_commit "$COMMIT_12" \
      --arg ksu_variant "$ksu" \
      '{version: $version, cr_ver: $cr_ver, cr_branch: $cr_branch, android_ver: $android_ver, boot_url: $boot_url, custom_commit: $custom_commit, ksu_variant: $ksu_variant}')
    TARGETS+=("$ENTRY")
  done
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
  echo "::error::未输入任何 boot.img 下载链接！请至少输入 boot_url_13 或 boot_url_12。"
  exit 1
fi

MATRIX_JSON=$(printf '%s\n' "${TARGETS[@]}" | jq -s -c '.')
echo "Generated matrix (${#TARGETS[@]} jobs): ${MATRIX_JSON}"
echo "matrix=${MATRIX_JSON}" >> "${GITHUB_OUTPUT}"

if [ -n "$URL_13" ] && [ -n "$URL_12" ]; then
  echo "built_versions=12_13" >> "${GITHUB_OUTPUT}"
elif [ -n "$URL_13" ]; then
  echo "built_versions=13" >> "${GITHUB_OUTPUT}"
else
  echo "built_versions=12" >> "${GITHUB_OUTPUT}"
fi
