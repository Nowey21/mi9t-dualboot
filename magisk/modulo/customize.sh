#!/system/bin/sh
# Magisk install hook: only davinci, and keep the scripts executable.
[ "$(getprop ro.product.device)" = davinci ] || abort "! Solo per Mi 9T (davinci)"
set_perm "$MODPATH/passa-a-ubuntu.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
ui_print "- Apri Moduli e tocca \"Azione\" su \"Passa a Ubuntu\" per riavviare in Ubuntu"
