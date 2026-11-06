#!/bin/bash
# Put the dual-boot helper, its polkit rule and Android's boot/dtbo backup into
# the device layer of the image (device/base is copied into the root filesystem).
#   MI9T_REPO  checkout of mi9t-mainline-linux (default ~/mi9t/mi9t-mainline-linux)
set -euo pipefail
S=$(cd "$(dirname "$0")" && pwd)
R=${MI9T_REPO:-$HOME/mi9t/mi9t-mainline-linux}/device/base
B=$S/../../backup
install -D -m 755 "$S/torna-ad-android" "$R/usr/local/sbin/torna-ad-android"
install -D -m 644 "$S/torna-ad-android.desktop" "$R/usr/share/applications/torna-ad-android.desktop"
install -D -m 644 "$S/50-torna-ad-android.rules" "$R/etc/polkit-1/rules.d/50-torna-ad-android.rules"
install -d -m 700 "$R/var/lib/mi9t-dualboot"
install -m 600 "$B/boot.img" "$B/dtbo.img" "$R/var/lib/mi9t-dualboot/"
(cd "$R/var/lib/mi9t-dualboot" && sha256sum boot.img dtbo.img > SHA256SUMS)
find "$R/var/lib/mi9t-dualboot" "$R/usr/local/sbin/torna-ad-android" -ls
