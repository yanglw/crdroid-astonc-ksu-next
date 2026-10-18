#!/usr/bin/env bash
set -euo pipefail

echo "=== [1/5] Freeing disk space ==="
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/share/boost

echo "=== [2/5] Configuring 24GB Swap ==="
sudo swapoff -a || true
sudo rm -f /swapfile
sudo fallocate -l 24G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=24576
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo 100 | sudo tee /proc/sys/vm/swappiness || true

echo "=== [3/5] Installing build dependencies ==="
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  bc bison build-essential curl flex git libelf-dev libssl-dev \
  zip binutils file dwarves pkg-config

echo "=== [4/5] Installing magiskboot ==="
AUTH_HEADER=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

MAGISK_URL=$(curl -s "${AUTH_HEADER[@]}" "https://api.github.com/repos/topjohnwu/Magisk/releases/latest" | grep "browser_download_url.*Magisk-.*\.apk" | head -n 1 | cut -d '"' -f 4 || true)
[ -z "$MAGISK_URL" ] && MAGISK_URL="https://github.com/topjohnwu/Magisk/releases/download/v30.7/Magisk-v30.7.apk"

curl -LSs -f "$MAGISK_URL" -o /tmp/magisk.apk
unzip -p /tmp/magisk.apk lib/x86_64/libmagiskboot.so > /tmp/magiskboot
chmod +x /tmp/magiskboot
sudo mv /tmp/magiskboot /usr/local/bin/magiskboot
rm -f /tmp/magisk.apk

echo "=== [5/5] Installing AOSP Clang toolchain ==="
curl -LSs -f -o /tmp/ndk.zip "https://dl.google.com/android/repository/android-ndk-r29-linux.zip"
mkdir -p "${GITHUB_WORKSPACE}/clang"
unzip -q /tmp/ndk.zip "android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/*" -d /tmp
mv /tmp/android-ndk-r29/toolchains/llvm/prebuilt/linux-x86_64/* "${GITHUB_WORKSPACE}/clang/"
rm -rf /tmp/ndk.zip /tmp/android-ndk-r29
"${GITHUB_WORKSPACE}/clang/bin/clang" --version
