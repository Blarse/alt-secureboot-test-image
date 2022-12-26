#!/bin/sh -eux

GRUB="git://git.altlinux.org/people/egori/packages/grub.git"
ALT_UEFI_CERTS="git://git.altlinux.org/gears/a/alt-uefi-certs.git"
REPO_DIR="$(readlink -m ./repo/RPMS.hasher)"

[ -d $REPO_DIR ] || mkdir -p $REPO_DIR
[ -d ./grub ] || git clone --depth=1 "$GRUB"
[ -d ./alt-uefi-certs ] || git clone --depth=1 "$ALT_UEFI_CERTS"

hsh-install -v $HASHER_DIR pesign nss-utils

pushd alt-uefi-certs
rm alt-uefi-certs/altlinux-ca.cer
cp "$KEYS_DIR/VENDOR.cer" alt-uefi-certs/altlinux-ca.cer
gear --zstd --commit -v ./pkg.tar
hsh-rebuild -v --repo-bin="$REPO_DIR" \
	    "$HASHER_DIR" ./pkg.tar
rm pkg.tar
popd

# Copy keys
rm -rf $HASHER_DIR/chroot/.host/nss
cp -r "$KEYS_DIR/nss" $HASHER_DIR/chroot/.host
chmod -R a+rx $HASHER_DIR/chroot/.host/nss

# Build grub
pushd grub
gear --zstd --commit -v ./pkg.tar

cat > $HASHER_DIR/chroot/.host/postinstall_sign << EOF
#!/bin/sh
for f in grubia32.efi grubx64.efi; do
pesign -v -s -c "Test Secure Boot VENDOR CA" -n "/.host/nss"\
       -i "/usr/src/tmp/grub-buildroot/usr/lib64/efi/\$f" \
       -o "/usr/src/tmp/grub-buildroot/usr/lib64/efi/\$f.signed"
mv /usr/src/tmp/grub-buildroot/usr/lib64/efi/\$f{.signed,}
done

EOF
chmod a+rx $HASHER_DIR/chroot/.host/postinstall_sign

hsh-rebuild -v --repo-bin="$REPO_DIR" \
	    --rpmbuild-args "--define=\"__spec_install_custom_post /.host/postinstall_sign\"" \
	    "$HASHER_DIR" ./pkg.tar

rm pkg.tar
popd
