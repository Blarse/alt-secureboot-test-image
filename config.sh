#!/bin/sh


#export TMPDIR=
#export ROOTDIR="$(readlink -f .)"
export ROOTDIR="$(dirname $(readlink -f $0))"
export WORKDIR="$ROOTDIR/build"
export KEYDIR="$ROOTDIR/keys"
export VMDIR="$ROOTDIR/vm"
export HASHERDIR="$WORKDIR/hasher"
export REPODIR="$WORKDIR/repo/RPMS.hasher"
export ROOTFSDIR="$WORKDIR/rootfs"
export ESPDIR="$ROOTFSDIR/boot/efi"

export SHIMDIR="$WORKDIR/shim"
export GRUBDIR="$WORKDIR/grub"

export ALT_SB_IMAGE="alt-sb.img"

# repos:
export SHIM_REPO="git://git.altlinux.org/people/egori/packages/shim.git"
export GRUB_REPO="git://git.altlinux.org/people/egori/packages/grub.git"
#export SHIM_REPO="git://git.altlinux.org/gears/s/shim.git"
#export GRUB_REPO="git://git.altlinux.org/gears/g/grub.git"

