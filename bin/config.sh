#!/bin/sh

# repos:
export SHIM_UNSIGNED="git://git.altlinux.org/people/egori/packages/shim.git"
export SHIM_SIGNED="git://git.altlinux.org/gears/s/shim-signed.git"
export GRUB="git://git.altlinux.org/people/egori/packages/grub.git"
export ALT_UEFI_CERTS="git://git.altlinux.org/gears/a/alt-uefi-certs.git"
export MKIMAGE_PROFILES="git://git.altlinux.org/gears/m/mkimage-profiles.git"
export KERNEL_IMAGE_STD_DEF="git://git.altlinux.org/gears/k/kernel-image-std-def.git"

#export TMPDIR=
export WORKDIR="$(readlink -f .)"
export HASHERDIR="$WORKDIR/hasher"
export REPODIR="$WORKDIR/repo/RPMS.hasher"
export KEYDIR="$WORKDIR/keys"
export ESPDIR="$WORKDIR/esp"
export ROOTFSDIR="$WORKDIR/rootfs"
