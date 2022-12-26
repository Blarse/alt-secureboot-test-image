#!/bin/sh -efu

if [ -d ./keys ]; then
    echo keys already exist
    exit 0
fi

mkdir -pv keys/nss
pushd keys

certutil -d "$PWD/nss" -N --empty-password

for t in PK KEK DB VENDOR; do

efikeygen -d "$PWD/nss" --ca --self-sign --nickname="Test Secure Boot $t CA" \
	  --common-name="CN=Test Secure Boot $t CA" --kernel

certutil -d "$PWD/nss" -L -n "Test Secure Boot $t CA" -a > $t.crt
done

certutil -d "$PWD/nss" -L -n "Test Secure Boot VENDOR CA" -r > VENDOR.cer

pk12util -d "$PWD/nss" -o VENDOR.p12 -n 'Test Secure Boot VENDOR CA' -K '' -W ''
popd
