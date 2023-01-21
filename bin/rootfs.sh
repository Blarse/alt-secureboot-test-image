#!/bin/sh -eu

DIR=$(dirname $(readlink -f $0))

source $DIR/config.sh
source $DIR/hasher.sh

hsh-install -v $HASHERDIR kernel-image-un-def make-initrd make-initrd-devmapper efibootmgr grub

hsh-run --rooter $HASHERDIR -- bash -c 'cd; cat > initrd.mk' <<EOF
PUT_PROGS += efibootmgr lsblk efivar
MODULES_PRELOAD += efivarfs
MODULES_ADD += drivers/scsi/ drivers/ata/ drivers/usb fs/ 

PUT_FILES += /root/bootmgr.sh

FEATURES = add-modules add-udev-rules modules-filesystem modules-network devmapper
DISABLE_GUESS = root ucode resume fstab
EOF

hsh-run --rooter $HASHERDIR -- bash -c 'cd; cat > bootmgr.sh; chmod +x bootmgr.sh' <<EOF
efibootmgr --unicode --disk /dev/sdX --part Y --create --label "signed" --loader /EFI/signed/BOOTX64.CSV

efibootmgr --unicode --disk /dev/sdX --part Y --create --label "unsigned" --loader /EFI/unsigned/BOOTX64.CSV

efibootmgr --unicode --disk /dev/sdX --part Y --create --label "notalt" --loader /EFI/notalt/BOOTX64.CSV
EOF


hsh-run --rooter --mountpoints=/proc,/sys $HASHERDIR -- bash -x <<EOF
make-initrd -c ~/initrd.mk -k \$(rpm -q --qf '%{VERSION}-un-def-%{RELEASE}' kernel-image-un-def)

cp -r /boot/ /usr/src
chmod 777 -R /usr/src/boot
chown -vR builder:  /usr/src/boot
EOF

hsh-run $HASHERDIR -- bash -x <<EOF
cp -r /usr/src/boot/ /.out/
EOF

mkdir -pv $ROOTFSDIR
cp -r $HASHERDIR/chroot/.out/boot $ROOTFSDIR
pushd $ROOTFSDIR/boot > /dev/null
rm config-* System.map-*
mv ./vmlinuz-* ./vmlinuz-unsigned
mv ./initrd-*.img ./initrd.img

pesign -n "$KEYDIR/nss" -f -s -c "SB TEST ALTSIG" \
       -i "vmlinuz-unsigned" \
       -o "vmlinuz-signed"
echo "sign 'vmlinuz-unsigned' -> 'vmlinuz-signed'"
pesign -n "$KEYDIR/nss" -f -s -c "SB TEST NOTALT" \
       -i "vmlinuz-unsigned" \
       -o "vmlinuz-notalt"
echo "sign 'vmlinuz-unsigned' -> 'vmlinuz-notalt'"

cat > grub/grub.cfg <<EOF
export GRUB_TERMINAL
export GRUB_SERIAL_COMMAND
if [ -n "\$GRUB_TERMINAL" ]; then
  \$GRUB_SERIAL_COMMAND
  terminal_output "\$GRUB_TERMINAL"
  terminal_input "\$GRUB_TERMINAL"
fi

insmod echo
insmod gzio
insmod minicmd
insmod normal
insmod test
set timeout=60
if [ "\$grub_platform" = "efi" ]; then set EFI_BOOTARGS=''; fi
if [ ! "\$lang" ]; then lang=en_US; fi

menuentry \$"Boot signed kernel" --id 'signed' {
    echo \$"Loading Signed Linux vmlinuz-signed ..."
    linux /boot/vmlinuz-signed
    echo \$"Loading initial ramdisk ..."
    initrd /boot/initrd.img
}

menuentry \$"Boot unsigned kernel" --id 'unsigned' {
    echo \$"Loading Unsigned Linux vmlinuz-unsigned ..."
    linux /boot/vmlinuz-unsigned
    echo \$"Loading initial ramdisk ..."
    initrd /boot/initrd.img
}

menuentry \$"Boot notalt kernel" --id 'notalt' {
    echo \$"Loading Notalt Linux vmlinuz-notalt ..."
    linux /boot/vmlinuz-notalt
    echo \$"Loading initial ramdisk ..."
    initrd /boot/initrd.img
}

if [ "\$grub_platform" = "efi" ]; then
    menuentry \$"UEFI Firmware Settings" --id 'uefi-firmware' {
        fwsetup
    }
fi
EOF

popd >/dev/null
