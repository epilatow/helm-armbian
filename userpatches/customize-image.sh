#!/bin/bash
set -eux

# Install overlays
OVERLAY=/tmp/overlay
find $OVERLAY -type f >&2
f=/boot/dtb/rockchip/rk3399-helm-v2a.dtb
install -D -m0644 $OVERLAY$f $f
for f in idbloader.bin uboot.img trust.bin; do
    f=/usr/lib/linux-u-boot-current-helm-v2a/$f
    install -D -m0644 $OVERLAY$f $f
done

exit 0
