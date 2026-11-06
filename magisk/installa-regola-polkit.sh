#!/system/bin/sh
# Run as root on Android: install the polkit rule that lets "Torna ad Android"
# run without a password, inside Ubuntu's linux_root.
set -e
T=/data/local/tmp/mi9t
M=/dev/mi9t_root
DEV=/dev/block/by-name/linux_root
# never write into a filesystem with errors (e.g. an interrupted first-boot grow)
r=0; e2fsck -f -p "$DEV" || r=$?
[ "$r" -lt 4 ] || { echo "linux_root ha errori: e2fsck -f -y $DEV, poi riprova" >&2; exit 1; }
mkdir -p "$M"
mount -t ext4 "$DEV" "$M"
trap 'umount "$M" 2>/dev/null' EXIT
ls "$M"/usr/lib/aarch64-linux-gnu/libpolkit-gobject-1.so.0.* 2>/dev/null | head -1
ls -ld "$M/etc/polkit-1/rules.d"
cp "$T/50-torna-ad-android.rules" "$M/etc/polkit-1/rules.d/50-torna-ad-android.rules"
chown 0:0 "$M/etc/polkit-1/rules.d/50-torna-ad-android.rules"
chmod 644 "$M/etc/polkit-1/rules.d/50-torna-ad-android.rules"
grep -c '' "$M/etc/polkit-1/rules.d/50-torna-ad-android.rules"
grep '^sudo:' "$M/etc/group"
sync
echo OK
