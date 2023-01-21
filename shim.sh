#!/bin/sh -eu

DIR=$(dirname $(readlink -f $0))

source $DIR/config.sh

# Build shim
if [ ! -s $REPODIR/shim-unsigned*.rpm -o \
       "${1:-}" = "-r" -o "${1:-}" = "--rebuild" ]
then
    echo "Building shim"

    # Spoof the cert
    rm -f $SHIMDIR/.gear/altlinux-ca.cer
    cp $KEYDIR/ALTCA.cer $SHIMDIR/.gear/altlinux-ca.cer

    source $DIR/hasher.sh
    GIT_DIR="$SHIMDIR/.git" GIT_WORK_TREE="$SHIMDIR" gear \
	   --zstd --commit -v --hasher -- \
	   hsh-rebuild -v --repo-bin=$REPODIR $HASHERDIR
else
    echo "Shim is already built, force rebuild with '-r' or '--rebuild'"
fi

# esp
mkdir -pv $ESPDIR/EFI
pushd $ESPDIR/EFI >/dev/null
mkdir -vp BOOT signed unsigned notalt enroll
mkdir -p shim
rpm2cpio $REPODIR/shim-unsigned*.rpm | cpio -id -D shim >/dev/null 2>&1
find shim \( -name '*.efi' -o -name '*.CSV' \) -exec cp -vf {} unsigned/ \;
rm -rf shim

# shim is always signed: we dont test firmware
for f in unsigned/shim{ia32,x64}.efi; do
    pesign -n "$KEYDIR/nss" -f -s -c "SB TEST ALTDB" \
    	   -i "$f" \
    	   -o "$f.signed"
    mv "$f.signed" "$f"
done
cp -vf unsigned/shim{ia32,x64}.efi signed/
cp -vf unsigned/shim{ia32,x64}.efi notalt/

printf 'shimx64.efi,altlinux-unsigned,,This is boot entry with unsigned grub\n' |
    sed -z -e 's/\(.\)/\1\x00/g' > unsigned/BOOTX64.CSV

printf 'shimia32.efi,altlinux-unsigned,,This is boot entry with unsigned grub\n' |
    sed -z -e 's/\(.\)/\1\x00/g' > unsigned/BOOTIA32.CSV

printf 'shimx64.efi,altlinux-signed,,This is boot entry with signed grub\n' |
    sed -z -e 's/\(.\)/\1\x00/g' > signed/BOOTX64.CSV

printf 'shimia32.efi,altlinux-signed,,This is boot entry with signed grub\n' |
    sed -z -e 's/\(.\)/\1\x00/g' > signed/BOOTIA32.CSV

printf 'shimx64.efi,altlinux-notalt,,This is boot entry with grub signed not by alt\n' |
    sed -z -e 's/\(.\)/\1\x00/g' > notalt/BOOTX64.CSV

printf 'shimia32.efi,altlinux-notalt,,This is boot entry with grub signed not by alt\n' |
    sed -z -e 's/\(.\)/\1\x00/g' > notalt/BOOTIA32.CSV

for f in {fb,mm}{ia32,x64}.efi; do
    pesign -n "$KEYDIR/nss" -f -s -c "SB TEST ALTSIG" \
    	   -i "unsigned/$f" \
    	   -o "signed/$f"
    echo "sign 'unsigned/$f' -> 'signed/$f'"
    pesign -n "$KEYDIR/nss" -f -s -c "SB TEST NOTALT" \
    	   -i "unsigned/$f" \
    	   -o "notalt/$f"
    echo "sing 'unsigned/$f' -> 'notalt/$f'"
done

cp -vf signed/shimia32.efi BOOT/BOOTIA32.EFI
cp -vf signed/shimx64.efi BOOT/BOOTX64.EFI
cp -vf signed/mm{ia32,x64}.efi BOOT/
cp -vf signed/fb{ia32,x64}.efi BOOT/

cp -vf $KEYDIR/ALTCA.cer enroll/
cp -vf $KEYDIR/ALTDB.cer enroll/

popd >/dev/null

