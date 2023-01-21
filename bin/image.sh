#!/bin/sh -eux



guestfish <<EOF
sparse sb.img 256M
run

part-init /dev/sda efi
part-add /dev/sda p 2048 206847
part-add /dev/sda p 206848 524254
mkfs fat /dev/sda1
mkfs ext4 /dev/sda2

mount /dev/sda2 /
copy-in rootfs/boot /
mkdir /boot/efi
mount /dev/sda1 /boot/efi
copy-in esp/EFI /boot/efi
umount /dev/sda1
umount /dev/sda2
EOF
