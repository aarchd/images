#!/bin/bash

set -euo pipefail

ROOTFS_PATH="${1}"
ROOTFS_SIZE=$(du -sm "$ROOTFS_PATH" | awk '{ print $1 }')

ARCHIVE_NAME="aarchd-rootfs-${1}"
WORK_DIR=${ARCHIVE_NAME}.work
IMG_SIZE=$(( "${ROOTFS_SIZE}" + 250 + 128 + 150 ))
IMG_MOUNTPOINT=".image"

clean() {
	rm -rf "${WORK_DIR}"
}
trap clean EXIT

echo "[*] Creating work directory"
mkdir -p "${WORK_DIR}"

echo "[*] Copying images from rootfs"
cp "${ROOTFS_PATH}"/boot/*.img* "${WORK_DIR}" || true
if [ "$(ls -A "${WORK_DIR}"/boot/*.img* 2>/dev/null)" ]; then
    echo "[*] Copied images:"
    ls -l "${WORK_DIR}"/boot/*.img*
else
    echo "[!] No images found in rootfs, continuing without them."
fi

echo "[*] Creating empty image (${IMG_SIZE}MB)"
dd if=/dev/zero of="${WORK_DIR}"/userdata.raw bs=1M count=${IMG_SIZE}

echo "[*] LVM setup"
DEVICE=$(losetup --find --show "${WORK_DIR}/userdata.raw")
echo "[*] Using loop device: ${DEVICE}"
pvcreate "${DEVICE}"
vgcreate aarchd "${DEVICE}"
echo "[*] Creating logical volumes"
lvcreate --zero n -L 128M -n aarchd-persistent aarchd
lvcreate --zero n -L 32M -n aarchd-reserved aarchd
lvcreate --zero n -l 100%FREE -n aarchd-rootfs aarchd
vgchange -ay aarchd
vgscan --mknodes -v
sleep 5
ROOTFS_VOLUME=$(realpath /dev/mapper/aarchd-aarchd--rootfs)

echo "[*] Formatting image with ext4"
mkfs.ext4 -F -O ^metadata_csum,^64bit,^orphan_file "${ROOTFS_VOLUME}"

echo "[*] Mounting image"
mkdir -p $IMG_MOUNTPOINT
mount "${ROOTFS_VOLUME}" "${IMG_MOUNTPOINT}"

echo "[*] Syncing rootfs"
rsync -aHAX "${ROOTFS_PATH}"/* "${IMG_MOUNTPOINT}"
rsync -aHAX "${ROOTFS_PATH}"/.[^.]* "${IMG_MOUNTPOINT}"
sync

echo "[*] Creating resize stamp"
mkdir -p ${IMG_MOUNTPOINT}/var/lib/halium
touch ${IMG_MOUNTPOINT}/var/lib/halium/requires-lvm-resize

echo "[*] Unmounting image"
umount "${IMG_MOUNTPOINT}"
vgchange -an aarchd
losetup -d "${DEVICE}"

echo "[*] Converting to sparse image"
img2simg "${WORK_DIR}/userdata.raw" "${WORK_DIR}/userdata.img"
rm -f "${WORK_DIR}/userdata.raw"

echo "[*] Creating archive"
cd "${WORK_DIR}"
tar -cf ../"${ARCHIVE_NAME}.tar.zst" --use-compress-program="zstd -19 -T0" .

echo "[✓] Done."
