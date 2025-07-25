#!/bin/bash

set -euo pipefail

echo "[*] Setting up User"

USERNAME=${1:-aarchd}
PASSWORD=${2:-3355}

echo "$USERNAME" > /etc/hostname
echo "127.0.0.1 $USERNAME" >> /etc/hosts

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

useradd -m -s /bin/bash "$USERNAME"

echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd

sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[*] Setting up User Directories"
pacman -S xdg-user-dirs --noconfirm
sudo -u "$USERNAME" -H bash -c "xdg-user-dirs-update"
pacman -Rns xdg-user-dirs --noconfirm

echo "[*] Configuring systemd services"
if pacman -Qi openssh &>/dev/null; then
    systemctl enable sshd
fi
systemctl enable lxc@android

chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

echo "[✓] System setup completed successfully"
