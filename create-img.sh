#!/bin/sh -efux



export HASHER_DIR="$(./create-hasher.sh)"
export KEYS_DIR="$(readlink -m ./keys)"
export REPO_DIR="$(readlink -m ./img/repo/RPMS.hasher)"
[ -d $REPO_DIR ] || mkdir -p $REPO_DIR

pushd img
echo Building shim ...
sleep 1
./shim.sh

echo Building grub ...
sleep 1
./grub.sh

popd
