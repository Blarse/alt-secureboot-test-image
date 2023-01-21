#!/bin/sh -eu

DIR=$(dirname $(readlink -f $0))

source $DIR/config.sh


#TODO: run in hasher
rm -rv $ALT_SB_IMAGE
echo "Building alt-sb.img"
guestfish <<EOF
sparse $ALT_SB_IMAGE 256M
run

part-init /dev/sda efi
part-add /dev/sda p 2048 206847
part-add /dev/sda p 206848 524254
mkfs fat /dev/sda1
mkfs ext4 /dev/sda2

mount /dev/sda2 /
mkdir /boot
mkdir /boot/efi
mount /dev/sda1 /boot/efi
copy-in $ROOTFSDIR/boot /

ls /boot/
ls /boot/efi

umount /dev/sda1
umount /dev/sda2
EOF
