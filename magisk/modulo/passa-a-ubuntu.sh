#!/system/bin/sh
# Mi 9T dual boot: Android -> Ubuntu, without a PC.
# 1. copies Android's current boot and dtbo to linux_esp/android/ (Ubuntu's
#    "Torna ad Android" restores them from there, so the copy is never stale)
# 2. puts U-Boot on boot and blanks dtbo (U-Boot does not start with Android's
#    overlay), then reboots.
# Nothing is written to boot/dtbo unless step 1 verified.
MODDIR=${0%/*}
BYNAME=/dev/block/by-name
MNT=/dev/mi9t_esp

fail() { echo "ERRORE: $*"; umount "$MNT" 2>/dev/null; exit 1; }

[ "$(id -u)" = 0 ] || fail "serve root"
[ "$(getprop ro.product.device)" = davinci ] || fail "non e' un Mi 9T (davinci)"
for p in boot dtbo linux_esp; do [ -b "$BYNAME/$p" ] || fail "manca la partizione $p"; done
cd "$MODDIR" || fail "cartella del modulo"
sha256sum -c uboot.img.sha256 >/dev/null 2>&1 || fail "uboot.img danneggiato"

echo "- salvo boot e dtbo di Android in linux_esp"
mkdir -p "$MNT"
mount -t vfat "$BYNAME/linux_esp" "$MNT" || fail "non riesco a montare linux_esp"
mkdir -p "$MNT/android" || fail "linux_esp in sola lettura?"
rm -f "$MNT/android/"*
for p in boot dtbo; do
	dd if="$BYNAME/$p" of="$MNT/android/$p.img" bs=4M 2>/dev/null || fail "copia di $p"
done
(cd "$MNT/android" && sha256sum boot.img dtbo.img > SHA256SUMS) || fail "checksum"
sync
for p in boot dtbo; do
	a=$(dd if="$BYNAME/$p" bs=4M 2>/dev/null | sha256sum | cut -d' ' -f1)
	b=$(sha256sum "$MNT/android/$p.img" | cut -d' ' -f1)
	[ "$a" = "$b" ] || fail "la copia di $p non corrisponde"
done
umount "$MNT" || fail "smontaggio di linux_esp"

echo "- scrivo U-Boot e svuoto dtbo"
dd if=/dev/zero of="$BYNAME/dtbo" bs=4M 2>/dev/null
dd if=uboot.img of="$BYNAME/boot" bs=4M conv=fsync 2>/dev/null || fail "scrittura di boot (Android NON avviabile: usa avvia-android.ps1 dal PC)"
sync
echo "- riavvio in Ubuntu"
sleep 2
reboot
