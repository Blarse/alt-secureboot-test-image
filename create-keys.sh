#!/bin/sh -efu

if [ -d ./keys ]; then
    echo keys already exist
    exit 0
fi

export HASHER_DIR="$(./create-hasher.sh)"

hsh-install -v "$HASHER_DIR" nss-utils pesign

hsh-run -v "$HASHER_DIR" -- bash <<EOF
cd /.out
rm -rf ./keys

mkdir -pv keys/nss
cd keys
certutil -d "./nss" -N --empty-password

for t in PK KEK DB VENDOR; do
efikeygen -d "./nss" --ca --self-sign --nickname="Test Secure Boot \$t CA" \
	  --common-name="CN=Test Secure Boot \$t CA" --kernel

certutil -d "./nss" -L -n "Test Secure Boot \$t CA" -a > \$t.crt
done

certutil -d "./nss" -L -n "Test Secure Boot VENDOR CA" -r > VENDOR.cer

pk12util -d "./nss" -o VENDOR.p12 -n 'Test Secure Boot VENDOR CA' -K '' -W ''

chmod +r -R .
EOF

cp -r "$HASHER_DIR/chroot/.out/keys" ./
