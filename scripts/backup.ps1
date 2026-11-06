# Backup delle partizioni del Mi 9T dalla recovery (adb root).
# Uso: telefono in recovery con ADB attivo, poi  .\scripts\backup.ps1
$ErrorActionPreference = 'Stop'
$dir = Join-Path $PSScriptRoot '..\backup'
New-Item -ItemType Directory -Force $dir | Out-Null
$parts = 'boot', 'dtbo', 'recovery', 'persist', 'modemst1', 'modemst2', 'fsg', 'fsc', 'cache'
foreach ($p in $parts) {
    $out = Join-Path $dir "$p.img"
    adb shell "dd if=/dev/block/by-name/$p of=/tmp/$p.img bs=4096 2>/dev/null"
    adb pull "/tmp/$p.img" $out | Out-Null
    adb shell "rm /tmp/$p.img"
    "{0,-10} {1,12} byte" -f $p, (Get-Item $out).Length
}
# GPT di sda (LUN 0): primaria (settori 0-5) e di riserva (ultimi 5 settori), settore 4096
$sectors = [int64](adb shell 'blockdev --getsz /dev/block/sda').Trim() / 8
adb shell "dd if=/dev/block/sda of=/tmp/gpt-primary.bin bs=4096 count=6 2>/dev/null"
adb shell "dd if=/dev/block/sda of=/tmp/gpt-backup.bin bs=4096 skip=$($sectors - 5) count=5 2>/dev/null"
foreach ($f in 'gpt-primary.bin', 'gpt-backup.bin') {
    adb pull "/tmp/$f" (Join-Path $dir $f) | Out-Null
    adb shell "rm /tmp/$f"
}
"sda: $sectors settori da 4096 byte" | Tee-Object (Join-Path $dir 'sda-sectors.txt')
Get-ChildItem $dir | Get-FileHash -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" } |
    Set-Content (Join-Path $dir 'SHA256SUMS')
