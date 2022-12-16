#!/bin/sh -efu

mkdir -pv vm

owner=$(uuidgen --namespace @dns --name alt-test --sha1)

rm -f ./vm/OVMF_VARS_4M.secboot.fd

virt-fw-vars --input /usr/share/OVMF/OVMF_VARS_4M.fd \
	     --output ./vm/OVMF_VARS_4M.secboot.fd \
	     --set-pk="$owner" ./keys/PK.crt \
             --add-kek="$owner" ./keys/KEK.crt \
	     --add-db="$owner" ./keys/DB.crt \
	     --distro-keys=alt \
	     --secure-boot
