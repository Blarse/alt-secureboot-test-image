#!/bin/sh -eux

MKIMAGE_PROFILES="git://git.altlinux.org/gears/m/mkimage-profiles.git"

[ -d ./mkimage-profiles ] || git clone --depth=1 "$MKIMAGE_PROFILES"

pushd ./mkimage-profiles
SOURCES_LIST=$(mktemp)
APT_CONFIG=$(mktemp)

cat > $SOURCES_LIST <<EOF
rpm-dir file:$(readlink -f ..) repo hasher
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

make DEBUG=1 APTCONF=$APT_CONFIG REPORT=1 live-rescue.iso
rm -f  ../../live-rescue-*.iso
mv $(readlink -f $TMP/out/live-rescue-latest-x86_64.iso) ../../

#make DEBUG=1 APTCONF=$APT_CONFIG REPORT=1 grub.iso
#rm -f  ../../grub-*.iso
#mv $(readlink -f $TMP/out/grub-latest-x86_64.iso) ../../

popd
