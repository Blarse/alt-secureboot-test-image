#!/bin/sh -efu

[ -d ./keys ] && exit 0

mkdir -pv keys
cd keys

certutil -d "$PWD" -N --empty-password

for t in PK KEK DB VENDOR; do

efikeygen -d "$PWD" --ca --self-sign --nickname="Test Secure Boot $t CA" \
	  --common-name="CN=Test Secure Boot $t CA" --kernel

certutil -d "$PWD" -L -n "Test Secure Boot $t CA" -a > $t.crt
done

certutil -d "$PWD" -L -n "Test Secure Boot VENDOR CA" -r > VENDOR.cer

pk12util -d "$PWD" -o VENDOR.p12 -n 'Test Secure Boot VENDOR CA' -K '' -W ''
