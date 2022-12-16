#!/bin/sh -eux

GRUB=""
ALT_UEFI_CERTS="git://git.altlinux.org/gears/a/alt-uefi-certs.git"
REPO_DIR="$(readlink -m ./repo/RPMS.hasher)"

[ -d $REPO_DIR ] || mkdir -p $REPO_DIR
[ -d ./grub ] || git clone --depth=1 "$GRUB"
[ -d ./alt-uefi-certs ] || git clone --depth=1 "$ALT_UEFI_CERTS"

WORKDIR="$TMP/secureboot-hasher"
if [ ! -d "$WORKDIR" ]; then
    mkdir $WORKDIR
    SOURCES_LIST=$(mktemp)
    APT_CONFIG=$(mktemp)

    cat > $SOURCES_LIST <<EOF
rpm http://mirror.yandex.ru altlinux/Sisyphus/x86_64 classic
rpm http://mirror.yandex.ru altlinux/Sisyphus/noarch classic
rpm http://mirror.yandex.ru altlinux/Sisyphus/x86_64-i586 classic
EOF

    cat > $APT_CONFIG <<EOF
Dir::Etc::main "/dev/null";
Dir::Etc::parts "/var/empty";
Dir::Etc::sourcelist "$SOURCES_LIST";
Dir::Etc::sourceparts "/var/empty";
APT::Cache-Limit "1073741824";
EOF

    # init hasher
    hsh -v --init --without-stuff --no-contents-indices \
	--pkg-build-list=+pesign,nss-utils \
	--apt-config=$APT_CONFIG $WORKDIR
fi

hsh-install -v $WORKDIR pesign nss-utils 

pushd alt-uefi-certs
rm alt-uefi-certs/altlinux-ca.cer
cp ../../keys/VENDOR.cer alt-uefi-certs/altlinux-ca.cer
gear --zstd --commit -v ./pkg.tar

hsh-rebuild -v --repo-bin="$REPO_DIR" \
	    "$WORKDIR" ./pkg.tar

rm pkg.tar
popd





# Copy keys
rm -rf $WORKDIR/chroot/.host/keys
cp -r ../keys $WORKDIR/chroot/.host
chmod -R a+rx $WORKDIR/chroot/.host/keys

# Build grub
pushd grub
gear --zstd --commit -v ./pkg.tar

cat > $WORKDIR/chroot/.host/postinstall_sign << EOF
#!/bin/sh
echo HELLO WORLD

for f in grubia32.efi grubx64.efi; do
pesign -v -s -c "Test Secure Boot VENDOR CA" -n "/.host/keys"\
       -i "/usr/src/tmp/grub-buildroot/usr/lib64/efi/\$f" \
       -o "/usr/src/tmp/grub-buildroot/usr/lib64/efi/\$f.signed"
mv /usr/src/tmp/grub-buildroot/usr/lib64/efi/\$f{.signed,}
done

EOF
chmod a+rx $WORKDIR/chroot/.host/postinstall_sign

hsh-rebuild -v --repo-bin="$REPO_DIR" \
	    --rpmbuild-args "--define=\"__spec_install_custom_post /.host/postinstall_sign\"" \
	    "$WORKDIR" ./pkg.tar

rm pkg.tar
popd
