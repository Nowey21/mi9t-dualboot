#!/bin/bash
# Build the dual-boot GPT for sda (LUN 0) of the Mi 9T from the backup in
# ../backup, on a sparse copy of the disk. Nothing is written to the phone.
#
#   userdata  #32  shrunk to $ANDROID_GIB GiB (Android, default 70)
#   bk08      #20  -> linux_esp   256 MiB, EFI System, after userdata (/dev/sda20)
#   bk09      #22  -> linux_root  the rest, Linux filesystem       (/dev/sda22)
#
# bk08 and bk09 are Xiaomi's blank spare partitions (all zeros); the table has
# only 32 entries and all are in use, so these two entries are moved to the end.
# Output: ../backup/new/gpt-primary.bin (sectors 0-5), gpt-backup.bin (last 5).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
B=$HERE/../backup
N=$B/new
SECT=$(sed -n 's/^sda: \([0-9]*\) .*/\1/p' "$B/sda-sectors.txt")   # from backup.ps1
ANDROID_GIB=${ANDROID_GIB:-70}
IMG=/var/tmp/mi9t-gpt/sda-new.img

mkdir -p /var/tmp/mi9t-gpt "$N"
rm -f "$IMG"
truncate -s $((SECT * 4096)) "$IMG"
dd if="$B/gpt-primary.bin" of="$IMG" bs=4096 conv=notrunc status=none
dd if="$B/gpt-backup.bin" of="$IMG" bs=4096 seek=$((SECT - 5)) conv=notrunc status=none
LOOP=$(losetup --sector-size 4096 -f --show "$IMG")
trap 'losetup -d "$LOOP"' EXIT

info() { sgdisk -i "$1" "$LOOP" | sed -n "s/^$2: //p"; }
[ "$(info 32 'Partition name')" = "'userdata'" ] || { echo "entry 32 is not userdata" >&2; exit 1; }
[ "$(info 20 'Partition name')" = "'bk08'" ] || { echo "entry 20 is not bk08" >&2; exit 1; }
[ "$(info 22 'Partition name')" = "'bk09'" ] || { echo "entry 22 is not bk09" >&2; exit 1; }
UD_START=$(info 32 'First sector' | cut -d' ' -f1)
UD_TYPE=$(info 32 'Partition GUID code' | cut -d' ' -f1)
UD_GUID=$(info 32 'Partition unique GUID')
LAST=$(info 32 'Last sector' | cut -d' ' -f1)

UD_END=$((UD_START + ANDROID_GIB * 262144 - 1))
ESP_START=$((UD_END + 1))
ESP_END=$((ESP_START + 65536 - 1))
ROOT_START=$((ESP_END + 1))

sgdisk -d 32 -n 32:$UD_START:$UD_END -t 32:$UD_TYPE -u 32:$UD_GUID -c 32:userdata \
	-d 20 -n 20:$ESP_START:$ESP_END -t 20:EF00 -c 20:linux_esp \
	-d 22 -n 22:$ROOT_START:$LAST -t 22:8300 -c 22:linux_root "$LOOP"
sgdisk -v "$LOOP"
sgdisk -p "$LOOP" | sed -n '/^Number/,$p' | grep -E '^ +(19|20|21|22|23|30|31|32) '

dd if="$IMG" of="$N/gpt-primary.bin" bs=4096 count=6 status=none
dd if="$IMG" of="$N/gpt-backup.bin" bs=4096 skip=$((SECT - 5)) count=5 status=none
(cd "$N" && sha256sum gpt-primary.bin gpt-backup.bin > SHA256SUMS)
echo "written: $N"
