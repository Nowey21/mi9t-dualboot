#!/bin/bash
# Build the Ubuntu images for the dual-boot Mi 9T (asks for the Ubuntu password)
# and copy them to ../../immagini. Run as root in WSL/Ubuntu.
#   MI9T_REPO  checkout of mi9t-mainline-linux with patches/ applied
#              (default ~/mi9t/mi9t-mainline-linux)
set -euo pipefail
S=$(cd "$(dirname "$0")" && pwd)
REPO=${MI9T_REPO:-$HOME/mi9t/mi9t-mainline-linux}
OUT=$S/../../immagini
export KERNEL_TGZ=${KERNEL_TGZ:-$HOME/mi9t-build/kernel-fix.tar.gz}
export IMAGE_USER=${IMAGE_USER:-ubuntu}
export IMAGE_TIMEZONE=${IMAGE_TIMEZONE:-Europe/Rome} IMAGE_LOCALE=${IMAGE_LOCALE:-it_IT.UTF-8} IMAGE_KEYMAP=${IMAGE_KEYMAP:-it}
echo "Utente Ubuntu: $IMAGE_USER  (la password che scegli serve per sudo e per lo sblocco)"
bash "$REPO/image/build-image.sh" 2>&1 | tee /tmp/image.log
mkdir -p "$OUT"
cp "$REPO"/dist/image/{uboot.img,esp.img,rootfs.img,SHA256SUMS} "$OUT/"
ls -l "$OUT"
echo "IMMAGINI PRONTE"
