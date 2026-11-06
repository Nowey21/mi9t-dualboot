# Scrive la tabella delle partizioni dual boot (da gpt-dualboot.sh) sul disco sda del telefono.
# Telefono in recovery LineageOS con ADB attivo.  .\scripts\scrivi-partizioni.ps1
# Scrive solo i settori 1-5 (header + voci) e gli ultimi 5 (copia di riserva); l'MBR resta com'e'.
# DOPO: la recovery deve formattare i dati (Factory reset -> Format data), userdata e' piu' piccola.
$ErrorActionPreference = 'Stop'
$b = Join-Path $PSScriptRoot '..\backup'
$n = Join-Path $b 'new'
foreach ($line in Get-Content (Join-Path $n 'SHA256SUMS')) {
    $hash, $name = $line -split '\s+', 2
    if ((Get-FileHash (Join-Path $n $name) -Algorithm SHA256).Hash.ToLower() -ne $hash) { throw "$name checksum errato" }
}
function sh([string]$c) { $o = adb shell $c; if ($LASTEXITCODE) { throw "adb shell fallito: $c" }; $o }
if ((sh 'getprop ro.product.device').Trim() -ne 'davinci') { throw 'non e'' un davinci' }
$sectors = [int64](sh 'blockdev --getsz /dev/block/sda').Trim() / 8
$expected = [int64]((Get-Content (Join-Path $b 'sda-sectors.txt')) -replace '^sda: (\d+) .*', '$1')
if ($sectors -ne $expected) { throw "sda ha $sectors settori, il backup ne indica $expected" }
# il disco deve avere ancora la tabella originale del backup
sh 'dd if=/dev/block/sda of=/tmp/cur.bin bs=4096 count=6 2>/dev/null' | Out-Null
adb pull /tmp/cur.bin (Join-Path $n 'cur.bin') | Out-Null
if ((Get-FileHash (Join-Path $n 'cur.bin')).Hash -ne (Get-FileHash (Join-Path $b 'gpt-primary.bin')).Hash) {
    throw 'la tabella sul telefono non e'' quella del backup: niente scritto'
}
adb push (Join-Path $n 'gpt-primary.bin') /tmp/p.bin | Out-Null
adb push (Join-Path $n 'gpt-backup.bin') /tmp/s.bin | Out-Null
sh "dd if=/tmp/p.bin of=/dev/block/sda bs=4096 skip=1 seek=1 count=5 conv=fsync 2>&1"
sh "dd if=/tmp/s.bin of=/dev/block/sda bs=4096 seek=$($sectors - 5) count=5 conv=fsync 2>&1"
sh 'sync'
# rilettura e verifica
sh "dd if=/dev/block/sda of=/tmp/p2.bin bs=4096 skip=1 count=5 2>/dev/null; dd if=/tmp/p.bin of=/tmp/p1.bin bs=4096 skip=1 count=5 2>/dev/null; cmp /tmp/p1.bin /tmp/p2.bin && echo primaria-ok"
sh "dd if=/dev/block/sda of=/tmp/s2.bin bs=4096 skip=$($sectors - 5) count=5 2>/dev/null; cmp /tmp/s.bin /tmp/s2.bin && echo riserva-ok"
'Tabella scritta. Ora riavvia nella recovery e formatta i dati.'
