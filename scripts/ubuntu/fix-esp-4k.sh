#!/bin/bash
# Rebuild an esp.img made before patches/0002 as FAT16 with 4096-byte sectors
# (the Mi 9T's UFS sector size; U-Boot refuses a 512-byte FAT on it), with the
# same files inside. Images built with the patches applied do not need this.
set -euo pipefail
S=$(cd "$(dirname "$0")" && pwd)
I=$S/../../immagini
W=/var/tmp/mi9t-esp4k
export MTOOLS_SKIP_CHECK=1
rm -rf "$W"; mkdir -p "$W/files"
mcopy -s -n -i "$I/esp.img" ::/ "$W/files/"
truncate -s 256M "$W/esp.img"
mkfs.vfat -F 16 -S 4096 -s 1 -n ESP "$W/esp.img" >/dev/null
mcopy -s -i "$W/esp.img" "$W/files/"* ::/
mdir -/ -i "$W/esp.img" ::/ | grep -vE '^$|Volume|Directory|files|bytes free'
fsck.vfat -n "$W/esp.img" | tail -2
cp "$W/esp.img" "$I/esp.img"
(cd "$I" && sha256sum esp.img rootfs.img uboot.img > SHA256SUMS)
