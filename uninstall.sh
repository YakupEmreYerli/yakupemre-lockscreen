#!/usr/bin/env bash
# Removes yakupemre-lockscreen and restores the stock Plasma lock screen.
# Usage: ./uninstall.sh
set -euo pipefail

id=yakupemre-lockscreen
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"

kwriteconfig6 --file plasmashellrc --group Shell --key ShellPackage --delete

rm -f "$config/systemd/user/plasma-plasmashell.service.d/$id.conf"
rmdir "$config/systemd/user/plasma-plasmashell.service.d" 2>/dev/null || true
systemctl --user daemon-reload

if [ -L "$config/plasma-$id-appletsrc" ]; then
    rm "$config/plasma-$id-appletsrc"
fi

rm -rf "${data:?}/plasma/shells/$id"

echo "Removed. The stock Plasma lock screen is back."
