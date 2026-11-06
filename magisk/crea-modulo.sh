#!/bin/bash
# Pack the Magisk module (with the current U-Boot) into passa-a-ubuntu.zip.
set -euo pipefail
H=$(cd "$(dirname "$0")" && pwd)
W=/var/tmp/mi9t-module
rm -rf "$W"; mkdir -p "$W"
cp -r "$H/modulo/." "$W/"
cp "$H/../immagini/uboot.img" "$W/"
(cd "$W" && sha256sum uboot.img > uboot.img.sha256)
find "$W" -type f \( -name '*.sh' -o -name update-binary -o -name updater-script -o -name module.prop \) -exec sed -i 's/\r$//' {} +
command -v zip >/dev/null || DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zip >/dev/null
rm -f "$H/passa-a-ubuntu.zip"
(cd "$W" && zip -q -r -X "$H/passa-a-ubuntu.zip" .)
unzip -l "$H/passa-a-ubuntu.zip"
