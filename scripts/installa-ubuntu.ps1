# Installa (o reinstalla) Ubuntu nelle partizioni linux_esp e linux_root del Mi 9T dual boot.
# Telefono in fastboot.  .\scripts\installa-ubuntu.ps1   (poi .\scripts\avvia-ubuntu.ps1)
# Android (userdata, boot, dtbo) non viene toccato.
$ErrorActionPreference = 'Stop'
$i = Join-Path $PSScriptRoot '..\immagini'
function fb { fastboot @args; if ($LASTEXITCODE) { throw "fastboot $($args -join ' ') fallito" } }
foreach ($line in Get-Content (Join-Path $i 'SHA256SUMS')) {
    $hash, $name = $line -split '\s+', 2
    $name = $name.TrimStart('*')
    if ((Get-FileHash (Join-Path $i $name) -Algorithm SHA256).Hash.ToLower() -ne $hash) { throw "$name checksum errato" }
    "$name ok"
}
if ((fastboot getvar product 2>&1 | Out-String) -notmatch 'product:\s*davinci') { throw 'nessun Mi 9T (davinci) in fastboot' }
foreach ($p in 'linux_esp', 'linux_root') {
    if ((fastboot getvar "partition-size:$p" 2>&1 | Out-String) -notmatch "partition-size:${p}:\s*0x") {
        throw "il telefono non ha la partizione ${p}: niente scritto"
    }
}
fb flash linux_esp (Join-Path $i 'esp.img')
fb flash linux_root (Join-Path $i 'rootfs.img')
'Ubuntu scritto. Per avviarlo:  .\scripts\avvia-ubuntu.ps1'
