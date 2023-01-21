#!/bin/sh -efu

DIR="$(dirname $(readlink -f $0))"

source "$DIR/config.sh"

mkdir -pv "$WORKDIR" "$REPODIR" "$ROOTFSDIR" "$ESPDIR" "$VMDIR"

if [ ! -d "$SHIMDIR" ]; then
    git clone --depth=4 "$SHIM_REPO" "$SHIMDIR"
fi

if [ ! -d "$GRUBDIR" ]; then
    git clone --depth=4 "$GRUB_REPO" "$GRUBDIR"
fi
