#!/system/bin/sh
# Run as root on Android: update Ubuntu's "Torna ad Android" and its fallback
# copy of boot/dtbo (now the Magisk boot) inside linux_root.
set -e
T=/data/local/tmp/mi9t
M=/dev/mi9t_root
mkdir -p "$M"
mount -t ext4 /dev/block/by-name/linux_root "$M"
trap 'umount "$M" 2>/dev/null' EXIT
cp "$T/torna-ad-android" "$M/usr/local/sbin/torna-ad-android"
chown 0:0 "$M/usr/local/sbin/torna-ad-android"
chmod 755 "$M/usr/local/sbin/torna-ad-android"
D="$M/var/lib/mi9t-dualboot"
dd if=/dev/block/by-name/boot of="$D/boot.img" bs=4M 2>/dev/null
dd if=/dev/block/by-name/dtbo of="$D/dtbo.img" bs=4M 2>/dev/null
(cd "$D" && sha256sum boot.img dtbo.img > SHA256SUMS && cat SHA256SUMS)
chmod 600 "$D/boot.img" "$D/dtbo.img"
sync
head -5 "$M/usr/local/sbin/torna-ad-android"
echo OK
