#!/bin/sh -eux

[ -d ./grub ] || git clone --depth=1 "$GRUB"
[ -d ./alt-uefi-certs ] || git clone --depth=1 "$ALT_UEFI_CERTS"

hsh-install -v $HASHER_DIR pesign nss-utils

pushd alt-uefi-certs
rm alt-uefi-certs/altlinux-ca.cer
cp "$KEYS_DIR/VENDOR.cer" alt-uefi-certs/altlinux-ca.cer
gear --zstd --commit -v --hasher -- \
     hsh-rebuild -v --repo-bin="$REPO_DIR" "$HASHER_DIR"
popd

# Copy keys
rm -rf $HASHER_DIR/chroot/.host/nss
cp -r "$KEYS_DIR/nss" $HASHER_DIR/chroot/.host
chmod -R a+rx $HASHER_DIR/chroot/.host/nss

# Build grub
pushd grub
cat > $HASHER_DIR/chroot/.host/postinstall_sign << EOF
#!/bin/sh
find /usr/src/tmp/grub-buildroot -name "*.efi" -type f \
     -exec pesign -v -s -c "Test Secure Boot VENDOR CA" -n "/.host/nss"\
       -i "{}" -o "{}.signed" \; -exec mv "{}.signed" "{}" \;
EOF
chmod a+rx $HASHER_DIR/chroot/.host/postinstall_sign

gear --zstd --commit -v --hasher -- \
     hsh-rebuild -v --repo-bin="$REPO_DIR" --rpmbuild-args \
     "--define=\"__spec_install_custom_post /.host/postinstall_sign\"" \
     "$HASHER_DIR"
rm -f $HASHER_DIR/chroot/.host/postinstall_sign
popd
