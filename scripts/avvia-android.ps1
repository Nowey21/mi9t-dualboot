# Dual boot Mi 9T: torna ad Android (da Ubuntu c'e' anche il comando "Torna ad Android").
# Telefono in fastboot (spento, poi Volume giu + accensione), poi:  .\scripts\avvia-android.ps1
# Rimette boot e dtbo di LineageOS salvati in backup\.
$ErrorActionPreference = 'Stop'
$b = Join-Path $PSScriptRoot '..\backup'
function fb { fastboot @args; if ($LASTEXITCODE) { throw "fastboot $($args -join ' ') fallito" } }
if ((fastboot getvar product 2>&1 | Out-String) -notmatch 'product:\s*davinci') {
    throw 'nessun Mi 9T (davinci) in fastboot'
}
fb flash dtbo (Join-Path $b 'dtbo.img')
fb flash boot (Join-Path $b 'boot.img')
fb reboot
'Avvio di Android in corso.'
