#!/bin/sh -eu

DIR=$(dirname $(readlink -f $0))

source $DIR/config.sh

[ -d ./grub ] || git clone --depth=1 "$GRUB"

mkdir -pv $REPODIR

if [ ! -s $REPODIR/grub-efi*.rpm -o "${1:-}" = "-r" -o "${1:-}" = "--rebuild" ]
then
    echo "Building grub"
    source $DIR/hasher.sh
    GIT_DIR="$PWD/grub/.git" GIT_WORK_TREE="$PWD/grub" gear \
	   --zstd --commit -v --hasher -- \
	   hsh-rebuild -v --repo-bin="$REPODIR" "$HASHERDIR"
else
    echo "Grub is already built, force rebuild with '-r' or '--rebuild'"
fi

mkdir -vp $ESPDIR/EFI/
pushd $ESPDIR/EFI >/dev/null
echo "Installing grub to '$ESPDIR/EFI'"
mkdir -vp signed unsigned notalt
mkdir -p grub
rpm2cpio $REPODIR/grub-efi*.rpm | cpio -id -D grub >/dev/null 2>&1
mv -v grub/usr/lib64/efi/grub{ia32,x64}.efi unsigned
rm -rf grub

for f in grub{ia32,x64}.efi; do
    pesign -n "$KEYDIR/nss" -f -s -c "SB TEST ALTSIG" \
    	   -i "unsigned/$f" \
    	   -o "signed/$f"
    echo "sign 'unsigned/$f' -> 'signed/$f'"
    pesign -n "$KEYDIR/nss" -f -s -c "SB TEST NOTALT" \
    	   -i "unsigned/$f" \
    	   -o "notalt/$f"
    echo "sign 'unsigned/$f' -> 'notalt/$f'"
done

cat > unsigned/grub.cfg <<EOF
search --file --set=root /boot/vmlinuz-notalt
set prefix=(\$root)/boot/grub
source \$prefix/grub.cfg
EOF
echo "wrote 'unsigned/grub.cfg'"
cp -vf unsigned/grub.cfg signed/grub.cfg
cp -vf unsigned/grub.cfg notalt/grub.cfg

popd >/dev/null
