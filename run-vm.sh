#!/bin/sh

set -Eeuxo pipefail

MACHINE_NAME="secureboot"
QEMU_IMG="./${MACHINE_NAME}.img"
SSH_PORT="5555"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.secboot.fd"
OVMF_VARS="./OVMF_VARS_4M.secboot.fd"

if [ ! -e "${QEMU_IMG}" ]; then
        qemu-img create -f qcow2 "${QEMU_IMG}" 8G
fi

qemu-system-x86_64 \
        -enable-kvm \
        -cpu host -smp cores=4,threads=1 -m 4096 \
        -name "${MACHINE_NAME}" \
        -object rng-random,filename=/dev/urandom,id=rng0 \
        -device virtio-rng-pci,rng=rng0 \
        -net nic,model=virtio -net user,hostfwd=tcp::${SSH_PORT}-:22 \
        -vga virtio \
        -machine q35,smm=on,accel=kvm \
        -global driver=cfi.pflash01,property=secure,value=on \
        -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on \
        -drive if=pflash,format=raw,unit=1,file="${OVMF_VARS}" \
	-cdrom ./*.iso \
        $@

#        -drive file="${QEMU_IMG}",format=qcow2 \

