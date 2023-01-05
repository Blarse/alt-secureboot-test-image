#!/bin/sh -eux

[ -d ./shim ] || git clone --depth=4 "$SHIM_UNSIGNED"
[ -d ./shim-signed ] || git clone --depth=1 "$SHIM_SIGNED"

# Spoof the cert
rm -f shim/.gear/altlinux-ca.cer
cp $KEYS_DIR/VENDOR.cer shim/.gear/altlinux-ca.cer

# Build shim-unsigned
pushd shim
git clean -fd
gear --zstd --commit -v --hasher -- \
     hsh-rebuild -v --repo-bin="$REPO_DIR" "$HASHER_DIR"
popd

# replace shim efi binaries in shim-signed and sign them
pushd shim-signed
rm -rf shim-signed
mkdir shim-signed
rpm2cpio $REPO_DIR/shim-unsigned*.rpm | cpio -ivd
find usr \( -name '*.efi' -o -name '*.CSV' \) -exec cp {} shim-signed/ \;
rm -rf usr

for f in shim-signed/shim{ia32,x64}.efi; do
    pesign -n "$KEYS_DIR/nss" -s -c "Test Secure Boot DB CA" \
    	   -i "$f" \
    	   -o "$f.signed"
    mv "$f.signed" "$f"
done

for f in shim-signed/{fb,mm}{ia32,x64}.efi; do
    pesign -n "$KEYS_DIR/nss" -s -c "Test Secure Boot VENDOR CA" \
    	   -i "$f" \
    	   -o "$f.signed"
    mv "$f.signed" "$f"
done

# build shim-signed
gear --zstd --commit -v --hasher -- \
     hsh-rebuild -v --repo-bin="$REPO_DIR" "$HASHER_DIR"
popd
