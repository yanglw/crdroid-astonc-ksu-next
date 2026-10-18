#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${GITHUB_WORKSPACE}/dist"
IMAGE_PATH="${GITHUB_WORKSPACE}/kernel/out/arch/arm64/boot/Image"
[ -f "$IMAGE_PATH" ] || { echo "::error::Kernel Image not found at $IMAGE_PATH"; exit 1; }

echo "=== [1/3] Packaging boot.img ==="
cd "${GITHUB_WORKSPACE}/repack"
cp "$IMAGE_PATH" kernel
magiskboot repack boot.img "${IMG_NAME}"
mv "${IMG_NAME}" "${GITHUB_WORKSPACE}/dist/"

echo "=== [2/3] Packaging AnyKernel3 Flashable Zip ==="
cd "${GITHUB_WORKSPACE}"
git clone --depth 1 https://github.com/osm0sis/AnyKernel3 AnyKernel3
git clone --depth 1 -b arm64-tools https://github.com/osm0sis/AnyKernel3 AnyKernel3-arm64
cp -f AnyKernel3-arm64/* AnyKernel3/tools/
rm -rf AnyKernel3-arm64 AnyKernel3/.git

# 写入针对 OnePlus Ace 3 / 12R (GKI init_boot 架构) 的 anykernel.sh
cat << 'EOF' > AnyKernel3/anykernel.sh
### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
# global properties
properties() { '
kernel.string=crDroid Kernel for OnePlus Ace 3 / 12R
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=astonc
device.name2=aston
device.name3=OnePlusAce3
device.name4=OnePlus12R
device.name5=OP594DL1
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties

### AnyKernel install
## boot shell variables
block=boot;
is_slot_device=auto;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh;

# GKI / init_boot 设备适配 (OnePlus Ace 3 / 12R 为 GKI 架构，ramdisk 位于 init_boot)
if [ -L "/dev/block/bootdevice/by-name/init_boot_a" ] || [ -L "/dev/block/by-name/init_boot_a" ]; then
    split_boot;
    flash_boot;
else
    dump_boot;
    write_boot;
fi;
EOF

# 动态注入内核标题
sed -i "s|kernel.string=.*|kernel.string=crDroid ${CR_VER} (${KSU_LABEL}) for OnePlus Ace 3 / 12R|g" AnyKernel3/anykernel.sh

cp "$IMAGE_PATH" AnyKernel3/Image
( cd AnyKernel3 && zip -r9 "${GITHUB_WORKSPACE}/dist/${AK3_NAME}" . -x '.git*' 'README.md' )

echo "=== [3/3] Saving Metadata ==="
cat << EOF > "${GITHUB_WORKSPACE}/dist/metadata_${CR_BRANCH}_${KSU_TAG}.env"
CR_BRANCH="${CR_BRANCH}"
CR_VER="${CR_VER}"
ANDROID_VER="${ANDROID_VER}"
SUBLEVEL="${SUBLEVEL}"
SHORT_SHA="${SHORT_SHA}"
FINAL_SHA="${FINAL_SHA}"
MODULES_SHA="${MODULES_SHA:-}"
MODULES_SHORT_SHA="${MODULES_SHORT_SHA:-}"
BOOT_URL="${BOOT_URL:-}"
KERNEL_BANNER="${KERNEL_BANNER:-}"
STOCK_UTS="${STOCK_UTS:-}"
DETECTED_SHA="${DETECTED_SHA:-}"
KSU_TAG="${KSU_TAG}"
KSU_LABEL="${KSU_LABEL}"
IMG_NAME="${IMG_NAME}"
AK3_NAME="${AK3_NAME}"
BUILD_DATE="${BUILD_DATE}"
EOF

echo "Packaging complete. Artifacts in ${GITHUB_WORKSPACE}/dist:"
ls -lh "${GITHUB_WORKSPACE}/dist"
