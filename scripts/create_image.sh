#!/bin/bash

set -euo pipefail

ROOTFS_PATH="${1}"
ROOTFS_SIZE=$(du -sm $ROOTFS_PATH | awk '{ print $1 }')

ARCHIVE_NAME="aarchd-rootfs-${1}"
WORK_DIR=${ARCHIVE_NAME}.work
IMG_SIZE=$(( ${ROOTFS_SIZE} + 250 ))
IMG_MOUNTPOINT=".image"

clean() {
	rm -rf ${WORK_DIR}
}
trap clean EXIT

echo "[*] Creating work directory"
mkdir -p ${WORK_DIR}

echo "[*] Copying images from rootfs"
cp "${ROOTFS_PATH}/boot/*.img*" "${WORK_DIR}/" || true
if [ "$(ls -A ${WORK_DIR}/boot/*.img* 2>/dev/null)" ]; then
    echo "[*] Copied images:"
    ls -l ${WORK_DIR}/boot/*.img*
else
    echo "[!] No images found in rootfs, continuing without them."
fi

echo "[*] Creating empty image (${IMG_SIZE}MB)"
dd if=/dev/zero of=${WORK_DIR}/userdata.raw bs=1M count=${IMG_SIZE}

echo "[*] Formatting image with ext4"
mkfs.ext4 -F -O ^metadata_csum,^64bit,^orphan_file "${WORK_DIR}/userdata.raw"

echo "[*] Mounting image"
mkdir -p $IMG_MOUNTPOINT
DEVICE=$(losetup --find --show "${WORK_DIR}/userdata.raw")
mount "${DEVICE}" "${IMG_MOUNTPOINT}"

echo "[*] Syncing rootfs"
rsync -aHAX ${ROOTFS_PATH}/* ${IMG_MOUNTPOINT}
rsync -aHAX ${ROOTFS_PATH}/.[^.]* ${IMG_MOUNTPOINT}
sync

echo "[*] Creating resize stamp"
mkdir -p ${IMG_MOUNTPOINT}/var/lib/halium
touch ${IMG_MOUNTPOINT}/var/lib/halium/requires-resize

echo "[*] Unmounting image"
umount "${IMG_MOUNTPOINT}"
rm -rf "${IMG_MOUNTPOINT}"
losetup -d "${DEVICE}"

echo "[*] Converting to sparse image"
img2simg "${WORK_DIR}/userdata.raw" "${WORK_DIR}/userdata.img"
rm -f "${WORK_DIR}/userdata.raw"

echo "[*] Creating archive"
cd "${WORK_DIR}"
tar -cf ../${ARCHIVE_NAME}.tar.zst --use-compress-program="zstd -19 -T0" .

echo "[✓] Done."
