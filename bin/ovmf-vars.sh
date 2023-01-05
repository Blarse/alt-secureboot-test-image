#!/bin/sh -eu

owner=$(uuidgen --namespace @dns --name alt-test --sha1)

if [ -f ./OVMF_VARS_4M.secboot.fd ]; then
    echo ./OVMF_VARS_4M.secboot.fd already exists
    exit 0
fi

hsh-install -v "$HASHER_DIR" python3-module-virt-firmware edk2-ovmf

rm -rf "$HASHER_DIR/chroot/.in/keys"
mkdir -pv "$HASHER_DIR/chroot/.in/keys"
cp "$KEYS_DIR"/{PK,KEK,DB}.crt "$HASHER_DIR/chroot/.in/keys"

hsh-run -v "$HASHER_DIR" -- bash <<EOF
virt-fw-vars --input /usr/share/OVMF/OVMF_VARS_4M.fd \
	     --output /.out/OVMF_VARS_4M.secboot.fd \
	     --set-pk="$owner" "/.in/keys/PK.crt" \
             --add-kek="$owner" "/.in/keys/KEK.crt" \
	     --add-db="$owner" "/.in/keys/DB.crt" \
	     --secure-boot
EOF
rm -rf "$HASHER_DIR/chroot/.in/keys"

cp "$HASHER_DIR/chroot/.out/OVMF_VARS_4M.secboot.fd" ./OVMF_VARS_4M.secboot.fd
