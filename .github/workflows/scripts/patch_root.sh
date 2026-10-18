#!/usr/bin/env bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}/kernel"

VARIANT="${KSU_VARIANT}"
case "${VARIANT}" in
  "KernelSU")
    KSU_TAG="ksu"
    KSU_LABEL="KernelSU (Official)"
    ;;
  "KernelSU-Next")
    KSU_TAG="ksu-next"
    KSU_LABEL="KernelSU-Next"
    ;;
  *)
    KSU_TAG="stock"
    KSU_LABEL="Stock (No Root)"
    ;;
esac

IMG_NAME="crdroid-${CR_VER}-${KSU_TAG}-boot-${BUILD_DATE}.img"
AK3_NAME="crdroid-${CR_VER}-${KSU_TAG}-AnyKernel3-${BUILD_DATE}.zip"

echo "KSU_TAG=${KSU_TAG}" >> "${GITHUB_ENV}"
echo "KSU_LABEL=${KSU_LABEL}" >> "${GITHUB_ENV}"
echo "IMG_NAME=${IMG_NAME}" >> "${GITHUB_ENV}"
echo "AK3_NAME=${AK3_NAME}" >> "${GITHUB_ENV}"

echo "=== Integrating Root: ${VARIANT} ==="
if [ "${VARIANT}" = "KernelSU-Next" ]; then
  echo "Integrating KernelSU-Next..."
  curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s next || \
  curl -LSs "https://raw.githubusercontent.com/rifsxd/KernelSU-Next/next/kernel/setup.sh" | bash -s next || {
    echo "Direct setup failed, cloning manually..."
    git clone --depth 1 -b next https://github.com/KernelSU-Next/KernelSU-Next.git KernelSU
    ln -sfn "${GITHUB_WORKSPACE}/kernel/KernelSU/kernel" "${GITHUB_WORKSPACE}/kernel/drivers/kernelsu"
  }
elif [ "${VARIANT}" = "KernelSU" ]; then
  echo "Integrating Official KernelSU..."
  curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash - || {
    git clone --depth 1 https://github.com/tiann/KernelSU.git KernelSU
    ln -sfn "${GITHUB_WORKSPACE}/kernel/KernelSU/kernel" "${GITHUB_WORKSPACE}/kernel/drivers/kernelsu"
  }
else
  echo "Stock build selected. Skipping KSU integration."
fi

# 注入 KSU 所需的 defconfig 配置项
if [ "${VARIANT}" != "Stock" ]; then
  for cfg in arch/arm64/configs/gki_defconfig "${GITHUB_WORKSPACE}/configs/stock.config"; do
    if [ -f "$cfg" ]; then
      cat << 'EOF' >> "$cfg"

# KernelSU Configurations
CONFIG_KSU=y
CONFIG_KSU_SUSFS=n
CONFIG_OVERLAY_FS=y
CONFIG_KPROBES=y
CONFIG_HAVE_KPROBES=y
CONFIG_KPROBE_EVENTS=y
EOF
    fi
  done
fi
