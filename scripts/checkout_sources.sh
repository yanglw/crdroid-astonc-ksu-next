#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/3] Resolving kernel commit ==="
TARGET_COMMIT="${CUSTOM_COMMIT:-}"
[ -z "$TARGET_COMMIT" ] && TARGET_COMMIT="${DETECTED_SHA:-}"

# 如果是短 SHA，解析为 40 位完整 SHA 以保证 shallow fetch 成功
if [ -n "$TARGET_COMMIT" ] && [ ${#TARGET_COMMIT} -lt 40 ]; then
  FULL_SHA=$(curl -s -f "https://api.github.com/repos/crdroidandroid/android_kernel_oneplus_sm8550/commits/${TARGET_COMMIT}" | grep -m1 '"sha":' | cut -d '"' -f 4 || true)
  [ -n "$FULL_SHA" ] && [ ${#FULL_SHA} -eq 40 ] && TARGET_COMMIT="$FULL_SHA"
fi

mkdir -p kernel && cd kernel
git init
git config advice.detachedHead false
git remote add origin https://github.com/crdroidandroid/android_kernel_oneplus_sm8550.git

if [ -n "$TARGET_COMMIT" ]; then
  echo "Fetching target commit: $TARGET_COMMIT"
  git fetch --depth 1 origin "$TARGET_COMMIT" || git fetch --depth 1 origin "${CR_BRANCH}"
  git checkout FETCH_HEAD
else
  echo "Fetching ${CR_BRANCH} HEAD..."
  git fetch --depth 1 origin "${CR_BRANCH}"
  git checkout FETCH_HEAD
fi

FINAL_SHA=$(git rev-parse HEAD)
SHORT_SHA=$(echo "${FINAL_SHA}" | cut -c1-12)
SUBLEVEL=$(grep "^SUBLEVEL =" Makefile | awk '{print $3}')
BUILD_DATE=$(date +'%Y%m%d')

echo "FINAL_SHA=${FINAL_SHA}" >> "${GITHUB_ENV}"
echo "SHORT_SHA=${SHORT_SHA}" >> "${GITHUB_ENV}"
echo "SUBLEVEL=${SUBLEVEL}" >> "${GITHUB_ENV}"
echo "BUILD_DATE=${BUILD_DATE}" >> "${GITHUB_ENV}"

echo "=== [2/3] Linking 18 hardware module drivers ==="
git clone --depth 1 -b "${CR_BRANCH}" https://github.com/crdroidandroid/android_kernel_oneplus_sm8550-modules.git "${GITHUB_WORKSPACE}/sm8550-modules"
MROOT="${GITHUB_WORKSPACE}/sm8550-modules"
MODULES_SHA=$(cd "$MROOT" && git rev-parse HEAD)
MODULES_SHORT_SHA=$(echo "${MODULES_SHA}" | cut -c1-12)
echo "MODULES_SHA=${MODULES_SHA}" >> "${GITHUB_ENV}"
echo "MODULES_SHORT_SHA=${MODULES_SHORT_SHA}" >> "${GITHUB_ENV}"

mkdir -p drivers/soc/oplus kernel/oplus_cpu
ln -sfn "$MROOT/oplus/kernel/cpu/thermal"                                   kernel/oplus_cpu/thermal
ln -sfn "$MROOT/oplus/kernel/touchpanel/kernelFwUpdate"                    drivers/base/kernelFwUpdate
ln -sfn "$MROOT/oplus/kernel/touchpanel/oplus_touchscreen_v2"              drivers/input/touchscreen/oplus_touchscreen_v2
ln -sfn "$MROOT/oplus/kernel/touchpanel/synaptics_hbp"                     drivers/input/touchscreen/synaptics_hbp
ln -sfn "$MROOT/oplus/kernel/touchpanel/oplus_touchscreen_v2/touch_custom" drivers/input/touchscreen/touch_custom
ln -sfn "$MROOT/oplus/secure/biometrics/fingerprints/bsp/uff/driver"       drivers/input/uff_fp_drivers
ln -sfn "$MROOT/oplus/kernel/leds/aw210xx"                                 drivers/leds/aw210xx
ln -sfn "$MROOT/oplus/kernel/vibrator/aw8697_haptic"                       drivers/misc/aw8697_haptic
ln -sfn "$MROOT/oplus/kernel/device_info/tri_state_key"                    drivers/misc/tri_state_key
ln -sfn "$MROOT/oplus/secure/common/bsp/drivers"                           drivers/misc/oplus_secure
ln -sfn "$MROOT/oplus/kernel/nfc"                                          drivers/nfc/oplus_nfc
ln -sfn "$MROOT/oplus/kernel/charger"                                      drivers/power/oplus
ln -sfn "$MROOT/oplus/kernel/boot"                                         drivers/soc/oplus/boot
ln -sfn "$MROOT/oplus/kernel/device_info/device_info"                      drivers/soc/oplus/device_info
ln -sfn "$MROOT/oplus/kernel/dfr"                                          drivers/soc/oplus/dfr
ln -sfn "$MROOT/oplus/kernel/dft"                                          drivers/soc/oplus/dft
ln -sfn "$MROOT/oplus/sensor/kernel/oplus_consumer_ir"                     drivers/soc/oplus/oplus_consumer_ir
ln -sfn "$MROOT/oplus/sensor/kernel/qcom/sensor"                           drivers/soc/oplus/sensor

echo "=== [3/3] Setting vermagic suffix ==="
if [ -n "${SCM_SUFFIX:-}" ]; then
  echo -n "${SCM_SUFFIX}" > .scmversion
else
  touch .scmversion
fi
