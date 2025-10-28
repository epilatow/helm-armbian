#!/usr/bin/env bash
# Host-side post-image hook: write u-boot blobs to LBAs.

post_build_image__vendor_artifacts() {
    echo "[vendor-artifacts] post_build_image started"
    (
        set -eux

        IMG="${FINAL_IMAGE_FILE:-}"
        [[ ! -f "$IMG" ]] && return 1

        OVERLAY=/armbian/userpatches/overlay
        DIR=/usr/lib/linux-u-boot-current-helm-v2a
        IDB="$OVERLAY/$DIR/idbloader.bin"
        UBT="$OVERLAY/$DIR/uboot.img"
        TRU="$OVERLAY/$DIR/trust.bin"

        # size sanity checks
        max_idb=$(( (0x4000 - 0x40) * 512 ))
        [[ "$(stat -c%s "$IDB")" -le "$max_idb" ]] || return 1
        max_4m=$(( 0x2000 * 512 ))
        [[ "$(stat -c%s "$UBT")" -le "$max_4m"  ]] || return 1
        [[ "$(stat -c%s "$TRU")" -le "$max_4m"  ]] || return 1

        dd if="$IDB" of="$IMG" bs=512 seek=$((0x40)) conv=notrunc status=none ||
            return 1
        dd if="$UBT" of="$IMG" bs=512 seek=$((0x4000)) conv=notrunc status=none || \
            return 1
        dd if="$TRU" of="$IMG" bs=512 seek=$((0x6000)) conv=notrunc status=none || \
            return 1
    ) || exit $?
    echo "[vendor-artifacts] post_build_image completed"
}
