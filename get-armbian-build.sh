#!/usr/bin/env bash
set -eux
ARMBIAN_REPO=https://github.com/armbian/build.git
ARMBIAN_TAG=v25.8.2
if [ ! -d build ]; then
    git clone --no-tags $ARMBIAN_REPO build
fi
cd build
git fetch --no-tags $ARMBIAN_REPO tag $ARMBIAN_TAG
git switch --detach $ARMBIAN_TAG
exit 0
