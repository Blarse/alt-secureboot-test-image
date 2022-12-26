#!/bin/sh -efu

# create hasher
if [ ! -d "$(readlink -m ./hasher)" ]; then
    HASHERDIR="$(mktemp -d -t sb-hasher.XXXXXXXXXX)"
    ln -svf "$HASHERDIR" ./hasher

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
	--apt-config=$APT_CONFIG ./hasher
fi
echo "$PWD/hasher"
