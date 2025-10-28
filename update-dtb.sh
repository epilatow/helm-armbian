#!/bin/bash
set -euxo pipefail
BRANCH=v6.12-helm-v2a
DTD_DIR=$(pwd)/userpatches/overlay/boot/dtb/rockchip
[[ ! -d helm-linux ]] && \
    git clone --filter=blob:none --branch $BRANCH \
    https://github.com/epilatow/linux.git helm-linux
(cd helm-linux; git pull)
(cd helm-linux; git checkout $BRANCH)

# Build an ubuntu kernel build image
docker build -t ubuntu-kernel-builder -<<'EOF'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive CCACHE_DIR=/ccache
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential bc flex bison libssl-dev libelf-dev \
    dwarves pahole ccache rsync python3 git fakeroot ca-certificates \
    clang lld llvm && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /src
EOF

# Build the DTB
docker run --rm -it \
    -v "$PWD"/helm-linux:/helm-linux -w /helm-linux \
    ubuntu-kernel-builder bash -lc '
    set -euxo pipefail
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- mrproper
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- DTC_FLAGS=-@ \
        rockchip/rk3399-helm-v2a.dtb
'
mkdir -p $DTD_DIR
cp helm-linux/arch/arm64/boot/dts/rockchip/rk3399-helm-v2a.dtb $DTD_DIR
exit 0
