#!/bin/sh -eux

[ -d ./kernel-image-un-def ] || git clone --depth=48 "$KERNEL_IMAGE_UN_DEF"

hsh-install -v $HASHER_DIR pesign nss-utils

# Copy keys
rm -rf $HASHER_DIR/chroot/.host/nss
cp -r "$KEYS_DIR/nss" $HASHER_DIR/chroot/.host
chmod -R a+rx $HASHER_DIR/chroot/.host/nss

# Build kernel-image-un-def
pushd kernel-image-un-def

cat > $HASHER_DIR/chroot/.host/postinstall_sign << EOF
#!/bin/sh
find /usr/src/tmp/kernel-image-un-def-buildroot -name "vmlinuz-*" -type f \
     -exec pesign -v -s -c "Test Secure Boot VENDOR CA" -n "/.host/nss" \
     -i "{}" -o "{}.signed" \; -exec mv "{}.signed" "{}" \;
EOF
chmod a+rx $HASHER_DIR/chroot/.host/postinstall_sign

git config --local gear.specsubst.kflavour un-def
git clean -fd
gear --zstd --commit -v --hasher -- \
     hsh-rebuild -v --repo-bin="$REPO_DIR" --rpmbuild-args \
     "--define=\"__spec_install_custom_post /.host/postinstall_sign\"" \
     "$HASHER_DIR"
rm -f $HASHER_DIR/chroot/.host/postinstall_sign
popd
