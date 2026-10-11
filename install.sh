#!/usr/bin/env bash
# Installs yakupemre-lockscreen for the current user and makes it the Plasma lock screen.
# Usage: ./install.sh        (run as your normal user, not root)
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    echo "Run as your normal user, not root." >&2
    exit 1
fi

for cmd in kwriteconfig6 systemctl; do
    command -v "$cmd" >/dev/null || { echo "Missing $cmd (needs Plasma 6)." >&2; exit 1; }
done

id=yakupemre-lockscreen
src="$(cd "$(dirname "$0")" && pwd)"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
dest="$data/plasma/shells/$id"

# 1. The package. Plasma loads the lock screen from the shell package named in
#    plasmashellrc; everything except the lock screen falls back to org.kde.plasma.desktop.
rm -rf "$dest"
install -d "$dest"
cp -r "$src/package/." "$dest/"

# 2. Point the lock screen at it.
kwriteconfig6 --file plasmashellrc --group Shell --key ShellPackage "$id"

# 3. plasmashell reads the same key, so pin the desktop itself to the stock shell.
dropin="$config/systemd/user/plasma-plasmashell.service.d"
install -d "$dropin"
cat > "$dropin/$id.conf" <<'EOF'
# Added by yakupemre-lockscreen: keep the desktop on the stock Plasma shell,
# only the lock screen comes from yakupemre-lockscreen.
[Service]
ExecStart=
ExecStart=/usr/bin/plasmashell --no-respawn --shell-plugin org.kde.plasma.desktop
EOF
systemctl --user daemon-reload

# 4. If plasmashell is ever started without the unit (plasmashell --replace), it would
#    look for plasma-<id>-appletsrc; point that at the real desktop layout.
layout="$config/plasma-org.kde.plasma.desktop-appletsrc"
alias_layout="$config/plasma-$id-appletsrc"
if [ -f "$layout" ] && [ ! -e "$alias_layout" ]; then
    ln -s "$(basename "$layout")" "$alias_layout"
fi

# 5. The lock screen reads the avatar from ~/.face.icon. KDE System Settings stores it
#    in AccountsService instead, so link that picture when there is no face icon yet.
face="$HOME/.face.icon"
accounts_icon="/var/lib/AccountsService/icons/$USER"
if [ ! -e "$face" ] && [ -r "$accounts_icon" ]; then
    ln -s "$accounts_icon" "$face"
fi

echo "Installed to $dest."
echo "Lock the screen (Meta+L) to see it. Preview without locking:"
echo "  /usr/lib/kscreenlocker_greet --testing --shell $dest"
