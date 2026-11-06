# Dual boot Mi 9T: passa ad Ubuntu.
# Telefono in fastboot (spento, poi Volume giu + accensione), poi:  .\scripts\avvia-ubuntu.ps1
# Svuota dtbo (U-Boot non parte con l'overlay di Android) e mette U-Boot su boot.
$ErrorActionPreference = 'Stop'
$img = Join-Path $PSScriptRoot '..\immagini\uboot.img'
if (-not (Test-Path $img)) { throw "manca $img" }
function fb { fastboot @args; if ($LASTEXITCODE) { throw "fastboot $($args -join ' ') fallito" } }
if ((fastboot getvar product 2>&1 | Out-String) -notmatch 'product:\s*davinci') {
    throw 'nessun Mi 9T (davinci) in fastboot'
}
fb erase dtbo
fb flash boot $img
fb reboot
'Avvio di Ubuntu in corso.'
