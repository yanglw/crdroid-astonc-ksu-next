#!/usr/bin/env bash
set -euo pipefail

cd "${GITHUB_WORKSPACE}/kernel"
export PATH="${GITHUB_WORKSPACE}/clang/bin:$PATH"

echo "=== Compiler Info ==="
clang --version

echo "=== Preparing Defconfig ==="
cp "${GITHUB_WORKSPACE}/configs/stock.config" arch/arm64/configs/stock_defconfig

make -j"$(nproc)" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  HOSTCC=gcc HOSTCXX=g++ HOSTAR=ar HOSTLD=ld \
  HOSTCFLAGS="-I/usr/include" HOSTLDFLAGS="-L/usr/lib/x86_64-linux-gnu" \
  stock_defconfig

make -j"$(nproc)" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  HOSTCC=gcc HOSTCXX=g++ HOSTAR=ar HOSTLD=ld \
  HOSTCFLAGS="-I/usr/include" HOSTLDFLAGS="-L/usr/lib/x86_64-linux-gnu" \
  olddefconfig

echo "=== Compiling Kernel Image (Full LTO) ==="
make -j"$(nproc)" O=out ARCH=arm64 LLVM=1 LLVM_IAS=1 \
  HOSTCC=gcc HOSTCXX=g++ HOSTAR=ar HOSTLD=ld \
  HOSTCFLAGS="-I/usr/include" HOSTLDFLAGS="-L/usr/lib/x86_64-linux-gnu" \
  Image

IMAGE_PATH="${GITHUB_WORKSPACE}/kernel/out/arch/arm64/boot/Image"
[ -f "$IMAGE_PATH" ] || { echo "::error::编译失败，未找到产物 Image！"; exit 1; }
echo "Kernel Image compiled successfully: $(ls -lh "$IMAGE_PATH" | awk '{print $5}')"
