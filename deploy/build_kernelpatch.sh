#!/bin/bash
set -ex
KERNEL_VERSION="6.8"
KERNEL_VERSION_UNDERSCORE="${KERNEL_VERSION//./_}"
DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPODIR="${DIR}/.."
BUILD_DIR="/tmp/linux"
TAG=$(git describe --tags --abbrev=0 | sed 's/[^0-9.]*//g')

echo "Build parameter:"
echo "KERNEL_VERSION: ${KERNEL_VERSION}"
echo "KERNEL_VERSION_UNDERSCORE: ${KERNEL_VERSION_UNDERSCORE}"
echo "DIR: ${DIR}"
echo "REPODIR: ${REPODIR}"
echo "BUILD_DIR: ${BUILD_DIR}"
echo "TAG: ${TAG}"

# Install the current clang and llvm
sudo apt-get update
sudo apt-get install clang-format clang-tidy clang-tools clang clangd libc++-dev libc++1 libc++abi-dev libc++abi1 libclang-dev libclang1 liblldb-dev libllvm-ocaml-dev libomp-dev libomp5 lld lldb llvm-dev llvm-runtime llvm python3-clang

# Recreate build dir
rm -rf "${BUILD_DIR}" || true
mkdir -p "${BUILD_DIR}"

# Clone
cd "${BUILD_DIR}"
git clone --depth 1 --branch "v${KERNEL_VERSION}" git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
cd ${BUILD_DIR}/linux
git checkout "v${KERNEL_VERSION}"

cp ${REPODIR}/kernel_module/${KERNEL_VERSION_UNDERSCORE}_patch/Kconfig ${BUILD_DIR}/linux/drivers/platform/x86
cp ${REPODIR}/kernel_module/${KERNEL_VERSION_UNDERSCORE}_patch/Makefile ${BUILD_DIR}/linux/drivers/platform/x86
cp ${REPODIR}/kernel_module/legion-laptop.c ${BUILD_DIR}/linux/drivers/platform/x86

cd ${BUILD_DIR}/linux
git config user.name "John Martens"
git config user.email "john.martens4@proton.me"
git add --all
git commit -m "Add legion-laptop v${TAG}

Add extra support for Lenovo Legion laptops.
"
git format-patch HEAD~1

## Dependencies for building
sudo apt-get install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev

# Clean
make clean && make LLVM=1 IAS=1 mrproper

# Create config with new module enabled
make LLVM=1 IAS=1 defconfig
# cp -v /boot/config-$(uname -r) .config
echo "CONFIG_LEGION_LAPTOP=m" >>.config

# Build
make LLVM=1 IAS=1 -j 8
