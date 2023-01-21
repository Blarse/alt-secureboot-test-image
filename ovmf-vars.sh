#!/bin/sh -eu

DIR=$(dirname $(readlink -f $0))

source $DIR/config.sh

owner=$(uuidgen --namespace @dns --name alt-test --sha1)

if [ -f $VMDIR/OVMF_VARS_4M.secboot.fd ]; then
    echo $VMDIR/OVMF_VARS_4M.secboot.fd already exists
    exit 0
fi

hsh-install -v "$HASHERDIR" python3-module-virt-firmware edk2-ovmf

rm -rf "$HASHERDIR/chroot/.in/keys"
mkdir -pv "$HASHERDIR/chroot/.in/keys"
cp "$KEYDIR"/{PK,KEK,ALTDB}.crt "$HASHERDIR/chroot/.in/keys"

hsh-run -v "$HASHERDIR" -- bash <<EOF
virt-fw-vars --input /usr/share/OVMF/OVMF_VARS_4M.fd \
	     --output /.out/OVMF_VARS_4M.secboot.fd \
	     --set-pk="$owner" "/.in/keys/PK.crt" \
             --add-kek="$owner" "/.in/keys/KEK.crt" \
	     --add-db="$owner" "/.in/keys/ALTDB.crt" \
	     --secure-boot
EOF
rm -rf "$HASHERDIR/chroot/.in/keys"

cp "$HASHERDIR/chroot/.out/OVMF_VARS_4M.secboot.fd" $VMDIR/OVMF_VARS_4M.secboot.fd
