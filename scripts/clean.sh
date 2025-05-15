#!/bin/bash
set -euo pipefail

pacman -Scc --noconfirm
rm -rf /var/lib/pacman/sync
rm -f /etc/machine-id
rm -rf /var/log/*
rm -rf /var/log/journal/*
rm -rf /var/lib/systemd/journal/*
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/lib/dhcp/*
rm -f /root/.bash_history
rm -f /home/*/.bash_history || true
rm -f /var/lib/systemd/random-seed
find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true
rm -rf /var/cache/man

echo "[*] Done. RootFS cleaned."
