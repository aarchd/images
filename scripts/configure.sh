#!/bin/bash

set -euo pipefail

echo "[*] Setting up system"

USERNAME=${1:-aarchd}
PASSWORD=${2:-3355}

echo $USERNAME > /etc/hostname
echo "127.0.0.1 $USERNAME" >> /etc/hosts

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

useradd -m -s /bin/bash "$USERNAME"

echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd

mkdir -p /etc/sudoers.d/
echo "$USERNAME ALL=(ALL) ALL" > "/etc/sudoers.d/00_$USERNAME"
chmod 0440 "/etc/sudoers.d/00_$USERNAME"

pacman -S xdg-user-dirs --noconfirm
sudo -u "$USERNAME" -H bash -c "xdg-user-dirs-update"
pacman -Rns xdg-user-dirs --noconfirm

systemctl enable sshd
systemctl enable lxc@android

chown -R $USERNAME:$USERNAME /home/$USERNAME

echo "[✓] System setup completed successfully"
