# Mi 9T dual boot: LineageOS + Ubuntu

Dual boot di **Android (LineageOS)** e **Ubuntu 24.04** (kernel mainline) sullo
**Xiaomi Mi 9T / Redmi K20 (`davinci`, Snapdragon 730)**, con un tasto per
passare da un sistema all'altro, senza PC.

Ubuntu viene da [SheroAbi/mi9t-mainline-linux](https://github.com/SheroAbi/mi9t-mainline-linux),
che però **sostituisce** Android. Questo repository aggiunge le patch e gli
script per tenerli tutti e due.

> ⚠ **Solo Mi 9T / Redmi K20 (`davinci`)**. Il Mi 9T **Pro** (`raphael`) è un
> altro telefono. Modificare la tabella delle partizioni è rischioso: fai il
> backup e leggi tutto prima di iniziare. Nessuna garanzia.
>
> Windows on ARM su `davinci` non esiste ancora (non c'è un UEFI funzionante),
> per questo qui si usa Ubuntu.

## Come funziona

| | |
|---|---|
| Android → Ubuntu | Magisk → **Moduli** → **Azione** su "Passa a Ubuntu" |
| Ubuntu → Android | app **"Torna ad Android"** (nessuna password) |
| Dal PC, in fastboot | `scripts\avvia-ubuntu.ps1` / `scripts\avvia-android.ps1` |

U-Boot (che avvia Ubuntu) **non parte se la partizione `dtbo` di Android è
presente**, e il bootloader Xiaomi rifiuta immagini con una propria
`recovery_dtbo`. Non si può quindi scegliere il sistema con i tasti: si
riscrivono `boot` e `dtbo`.

- **Passa a Ubuntu** (modulo Magisk) copia `boot` e `dtbo` *attuali* di
  Android in `linux_esp/android/`, verifica la copia, poi scrive U-Boot su
  `boot`, azzera `dtbo` e riavvia.
- **Torna ad Android** rimette quella copia (sempre aggiornata, anche dopo un
  aggiornamento di LineageOS o con Magisk), oppure la copia presa
  all'installazione se manca.

### Partizioni

La tabella GPT di `sda` ha **solo 32 voci, tutte usate**. Si riusano le due
partizioni di riserva Xiaomi `bk08` e `bk09` (vuote, verificate tutte a zero),
spostandole in fondo dopo aver ristretto `userdata`:

| Voce | Nome | Dimensione (128 GB) | Uso |
|---|---|---|---|
| 32 | `userdata` | 70 GiB (`ANDROID_GIB`) | Android |
| 20 | `linux_esp` (era `bk08`) | 256 MiB, FAT16, settori 4096 | U-Boot → systemd-boot, kernel, DTB |
| 22 | `linux_root` (era `bk09`) | il resto (~41 GiB) | Ubuntu, `/dev/sda22` |

Il resto della tabella non cambia. La recovery di LineageOS resta, quindi gli
aggiornamenti OTA funzionano.

## Requisiti

- Mi 9T `davinci` con **bootloader sbloccato** e LineageOS.
- PC Windows con [platform-tools](https://developer.android.com/tools/releases/platform-tools)
  (`adb`, `fastboot`), PowerShell 7 e **WSL2** con Ubuntu per la compilazione.
- Recovery LineageOS (ADB con root).
- [Magisk](https://github.com/topjohnwu/Magisk/releases) per il tasto senza PC.

## Installazione

> L'ordine conta. Il passo 4 **cancella i dati di Android** (non il sistema).

1. **Backup**: telefono in recovery LineageOS, *Advanced → Enable ADB*:

   ```powershell
   .\scripts\backup.ps1
   ```

   Salva in `backup\` `boot`, `dtbo`, `recovery`, `persist`, le partizioni
   modem/IMEI (`modemst1/2`, `fsg`, `fsc`), `cache` e la GPT. **Tienilo
   privato** (contiene dati unici del tuo telefono) e al sicuro.

2. **Compila** in WSL (come root) il progetto con le patch:

   ```bash
   git clone https://github.com/SheroAbi/mi9t-mainline-linux ~/mi9t/mi9t-mainline-linux
   cd ~/mi9t/mi9t-mainline-linux
   git am /percorso/di/questo/repo/patches/*.patch
   ```

   Pacchetti: quelli del README del progetto, ma su Ubuntu ≥ 24.10
   `qemu-user-static` non esiste: installa `qemu-user qemu-user-binfmt` e crea
   `ln -s qemu-aarch64 /usr/bin/qemu-aarch64-static`; serve anche `zstd`.

   ```bash
   bash scripts/build/build-kernel.sh
   bash /percorso/di/questo/repo/scripts/ubuntu/stage-dualboot.sh   # Torna ad Android + copia di boot/dtbo
   bash /percorso/di/questo/repo/scripts/ubuntu/build-image.sh      # chiede la password di Ubuntu
   ```

   Le immagini finiscono in `immagini\`.

3. **Nuova tabella delle partizioni** (solo sul PC, non scrive nulla):

   ```bash
   bash scripts/gpt-dualboot.sh        # ANDROID_GIB=70 di default
   ```

4. **Scrivila** (recovery con ADB attivo). Scrive solo header e voci GPT, non
   l'MBR, e si rifiuta se la tabella sul telefono non è quella del backup:

   ```powershell
   .\scripts\scrivi-partizioni.ps1
   ```

   Poi riavvia in recovery: *Factory reset → Format data/factory reset*.

5. **Installa Ubuntu** (fastboot) e avvialo:

   ```powershell
   .\scripts\installa-ubuntu.ps1
   .\scripts\avvia-ubuntu.ps1
   ```

6. **Tasto senza PC**: installa Magisk (patch di `boot.img` dall'app, poi
   `fastboot flash boot magisk_patched-*.img`), quindi crea e installa il modulo:

   ```bash
   bash magisk/crea-modulo.sh          # -> magisk/passa-a-ubuntu.zip
   ```

   Installa lo zip da Magisk → Moduli e **riavvia** (il pulsante Azione
   compare solo dopo il riavvio). Dopo aver installato Magisk, rimetti in
   `backup\boot.img` la versione patchata, così `avvia-android.ps1` mantiene il
   root.

Se hai un Ubuntu già installato senza la regola polkit o con il vecchio
"Torna ad Android", `magisk/aggiorna-ubuntu.sh` e
`magisk/installa-regola-polkit.sh` li aggiornano da Android (root) montando
`linux_root`.

## Cose imparate

- **Tabella da 32 voci**: non si possono aggiungere partizioni, solo riusarne.
- **dtbo**: U-Boot non si avvia con l'overlay di Android; un'immagine boot
  header v1 con `recovery_dtbo` propria viene rifiutata ("Load Error").
- **FAT con settori da 4096**: sulla UFS del telefono U-Boot rifiuta una FAT
  con settori da 512 (`FAT sector size mismatch`). Per 256 MiB con settori da 4K
  il formato corretto è FAT16.
- **su di LineageOS**: nelle build `userdebug` `/product/bin/su` copre quello
  di Magisk; via ADB usa `/debug_ramdisk/su`.
- **Primo avvio di Ubuntu**: il filesystem viene ingrandito fino a tutta la
  partizione. Se lo interrompi (per esempio tornando subito ad Android) resta
  piccolo e con errori (`EXT4-fs error … bad block bitmap checksum`) e
  Ubuntu si blocca. Si ripara da Android con root, a partizione smontata:
  `e2fsck -f -y /dev/block/by-name/linux_root` e poi
  `resize2fs /dev/block/by-name/linux_root`. Gli script in `magisk/` si
  rifiutano di scrivere su un filesystem con errori.
- **fastboot bloccato** dopo flash grandi (seriale `????`): stacca e riattacca il cavo.

## Ritorno ad Android puro

Rimetti la tabella originale dal tuo backup (`backup\gpt-primary.bin`
settori 1–5 e `gpt-backup.bin` in fondo a `sda`, dalla recovery), `boot.img` e
`dtbo.img` originali, poi *Format data*. Oppure flasha la ROM fastboot ufficiale
Xiaomi e reinstalla LineageOS.

## Licenza

GPL-2.0, come il progetto da cui derivano le patch. Ubuntu, U-Boot, il kernel e
Magisk hanno le loro licenze e non sono inclusi qui.
