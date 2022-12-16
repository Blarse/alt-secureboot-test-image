#!/bin/sh -eux

#plan:
# 1. build shim-unsigned
# 2. extract efi binaries
# 3. replace shim efi binaries in shim-signed
# 4. sign shim
# 5. build shim-signed

SHIM_UNSIGNED="git://git.altlinux.org/people/egori/packages/shim.git"
SHIM_SIGNED="git://git.altlinux.org/gears/s/shim-signed.git"
REPO_DIR="$(readlink -m ./repo/RPMS.hasher)"

[ -d $REPO_DIR ] || mkdir -p $REPO_DIR
[ -d ./shim ] || git clone --depth=4 "$SHIM_UNSIGNED"
[ -d ./shim-signed ] || git clone --depth=1 "$SHIM_SIGNED"

# prepare hasher
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
	--apt-config=$APT_CONFIG $WORKDIR
fi

# Spoof the cert
rm -f shim/.gear/altlinux-ca.cer
cp ../keys/VENDOR.cer shim/.gear/altlinux-ca.cer

# Build shim-unsigned
pushd shim
git clean -fd
gear --zstd --commit -v ./pkg.tar
hsh-rebuild -v --repo-bin="$REPO_DIR" "$WORKDIR" ./pkg.tar
rm pkg.tar
popd

# replace shim efi binaries in shim-signed and sign them
pushd shim-signed
rm -rf shim-signed
mkdir shim-signed
rpm2cpio $REPO_DIR/shim-unsigned*.rpm | cpio -ivd
find usr \( -name '*.efi' -o -name '*.CSV' \) -exec cp {} shim-signed/ \;
rm -rf usr

for f in shim-signed/shim{ia32,x64}.efi; do
    pesign -n "../../keys" -s -c "Test Secure Boot DB CA" \
    	   -i "$f" \
    	   -o "$f.signed"
    mv "$f.signed" "$f"
done

for f in shim-signed/{fb,mm}{ia32,x64}.efi; do
    pesign -n "../../keys" -s -c "Test Secure Boot VENDOR CA" \
    	   -i "$f" \
    	   -o "$f.signed"
    mv "$f.signed" "$f"
done

# build shim-signed
gear --zstd --commit -v ./pkg.tar
hsh-rebuild -v --repo-bin="$REPO_DIR" "$WORKDIR" ./pkg.tar
rm pkg.tar
popd
