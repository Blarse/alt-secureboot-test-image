#!/bin/sh -efu

cd $(dirname $(readlink -f $0))

./setup.sh
./shim.sh
./grub.sh
./rootfs.sh
./image.sh
./ovmf-vars.sh
./run-vm.sh
