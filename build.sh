#!/bin/sh -eu

export HASHER_BASE="$TMPDIR"

PATH="$PWD/bin:$PATH"
export BUILD_DIR="$PWD/build"
export HASHER_DIR="$BUILD_DIR/hasher"
export REPO_DIR="$BUILD_DIR/repo/RPMS.hasher"
export KEYS_DIR="$BUILD_DIR/keys"

# repos:
export SHIM_UNSIGNED="git://git.altlinux.org/people/egori/packages/shim.git"
export SHIM_SIGNED="git://git.altlinux.org/gears/s/shim-signed.git"
export GRUB="git://git.altlinux.org/people/egori/packages/grub.git"
export ALT_UEFI_CERTS="git://git.altlinux.org/gears/a/alt-uefi-certs.git"
export MKIMAGE_PROFILES="git://git.altlinux.org/gears/m/mkimage-profiles.git"
export KERNEL_IMAGE_STD_DEF="git://git.altlinux.org/gears/k/kernel-image-std-def.git"

mkdir -pv $BUILD_DIR
pushd $BUILD_DIR

hasher.sh
keys.sh

shim.sh
grub.sh
kernel.sh
image.sh
popd

mv build/*.iso . ||:
ovmf-vars.sh
