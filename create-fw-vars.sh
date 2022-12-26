#!/bin/sh -efu

mkdir -pv vm

owner=$(uuidgen --namespace @dns --name alt-test --sha1)

rm -i ./vm/OVMF_VARS_4M.secboot.fd
if [ -e ./vm/OVMF_VARS_4M.secboot.fd ]; then
    echo nothing to do
    exit 0
fi

virt-fw-vars --input /usr/share/OVMF/OVMF_VARS_4M.fd \
	     --output ./vm/OVMF_VARS_4M.secboot.fd \
	     --set-pk="$owner" ./keys/PK.crt \
             --add-kek="$owner" ./keys/KEK.crt \
	     --add-db="$owner" ./keys/DB.crt \
	     --secure-boot
#	     --distro-keys=alt \
