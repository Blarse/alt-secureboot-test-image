#!/bin/sh -eu
#
# Naming scheme:
# PK - Platform Key
# KEK - Key Exchange Key
# ALTDB - mimics Microsoft Windows UEFI Driver Publisher
# ALTCA - ALT UEFI SB CA
# ALTSIG - ALT UEFI SB SIGNER
# NOTALT - Not signed by ALTCA
#
# What signes what
# - PK and KEK required to enable SB in OVMF
# - ALTDB signs shim{ia32,x64}.efi
# - ALTCA signs ALTSIG
# - ALTSIG signs {mm,fb}{ia32,x64}.efi and grub{ia32,x64}.efi
# - NOTALT ...
#
# Verification
# - ALTDB enrolled in DB verifies shim{ia32,x64}.efi
# - ALTCA gose into shim{ia32,x64}.efi
# - shim verifies binaries signed with ALTSIG
# - grub uses shim_lock uefi interface for verification
# - shim(thus grub) fails to verify binaries signed with NOTALT
#

DIR=$(dirname $(readlink -f $0))

mkdir -v ./keys

source $DIR/config.sh
source $DIR/hasher.sh

hsh-install -v $HASHERDIR nss-utils pesign
hsh-run -v $HASHERDIR -- bash <<EOF
cd /.out
rm -rf ./keys

mkdir -pv keys/nss
cd keys
certutil -d "./nss" -N --empty-password

# Create CAs
for t in PK KEK ALTDB ALTCA NOTALT; do
efikeygen -d "./nss" --ca --self-sign --kernel \
	  --nickname="SB TEST \$t" \
	  --common-name="CN=SB TEST \$t"

certutil -d "./nss" -L -n "SB TEST \$t" -a > \$t.crt
done

# Create signer
efikeygen -d "./nss" --signer="SB TEST ALTCA" --kernel \
	  --nickname="SB TEST ALTSIG" \
	  --common-name="CN=SB TEST ALTSIG"

certutil -d "./nss" -L -n "SB TEST ALTCA" -r > ALTCA.cer
certutil -d "./nss" -L -n "SB TEST ALTDB" -r > ALTDB.cer

chmod +r -R .
EOF

cp -r $HASHERDIR/chroot/.out/keys/* ./keys
hsh-run -v $HASHERDIR -- rm -rf /.out/keys
