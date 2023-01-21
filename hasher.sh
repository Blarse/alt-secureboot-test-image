#!/bin/sh -efu

if [ -d "$HASHERDIR/chroot" ]; then
    echo "Using existing hasher: $HASHERDIR"
else
    [ -d "$(readlink -f $HASHERDIR)" ] || \
      ln -svf "$(mktemp -d -t sb-hasher.XXXXXXXXXX)" "$HASHERDIR"

    SOURCES_LIST=$(mktemp)
    APT_CONFIG=$(mktemp)
    
    cat > $SOURCES_LIST <<EOF
rpm-dir file:$(dirname $(dirname $REPODIR)) $(basename $(dirname $REPODIR)) hasher
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
	--apt-config=$APT_CONFIG $HASHERDIR

    rm $SOURCES_LIST $APT_CONFIG
fi
