#!/bin/bash

set -euo pipefail

ROOTFS_PATH="${1}"
ROOTFS_SIZE=$(du -sm $ROOTFS_PATH | awk '{ print $1 }')

ZIP_NAME="aarchd-rootfs-${1}"
WORK_DIR=${ZIP_NAME}.work
IMG_SIZE=$(( ${ROOTFS_SIZE} + 250 + 128 + 150 )) # FIXME 250MB + 128MB + 150MB contingency
IMG_MOUNTPOINT=".image"

clean() {
	rm -rf ${WORK_DIR}
}
trap clean EXIT

# Crate temporary directory
mkdir ${ZIP_NAME}.work

# copy .img from rootfs if exists
cp ${ROOTFS_PATH}/boot/boot.img ${WORK_DIR}/boot.img || true
cp ${ROOTFS_PATH}/boot/dtbo.img ${WORK_DIR}/boot.img || true
cp ${ROOTFS_PATH}/boot/recovery.img ${WORK_DIR}/recovery.img || true
cp ${ROOTFS_PATH}/boot/vbmeta.img ${WORK_DIR}/vbmeta.img || true

# create target base image
echo "Creating empty image"
dd if=/dev/zero of=${WORK_DIR}/userdata.raw bs=1M count=${IMG_SIZE}

# Loop mount
echo "Mounting image"
DEVICE=$(losetup -f)

losetup ${DEVICE} ${WORK_DIR}/userdata.raw

# Create LVM physical volume
echo "Creating PV"
pvcreate ${DEVICE}

# Create LVM volume group
echo "Creating VG"
vgcreate aarchd "${DEVICE}"

# Create LVs, currently
# 1) aarchd-persistent (128M)
# 2) aarchd-reserved (32M)
# 3) aarchd-rootfs (rest)
echo "Creating LVs"
lvcreate --zero n -L 128M -n aarchd-persistent aarchd
lvcreate --zero n -L 32M -n aarchd-reserved aarchd
lvcreate --zero n -l 100%FREE -n aarchd-rootfs aarchd

vgchange -ay aarchd
vgscan --mknodes -v

sleep 5

ROOTFS_VOLUME=$(realpath /dev/mapper/aarchd-aarchd--rootfs)

# Create rootfs filesystem
echo "Creating rootfs filesystem"
mkfs.ext4 -O ^metadata_csum -O ^64bit -O ^orphan_file ${ROOTFS_VOLUME}

# mount the image
echo "Mounting root image"
mkdir -p $IMG_MOUNTPOINT
mount ${ROOTFS_VOLUME} ${IMG_MOUNTPOINT}

# copy rootfs content
echo "Syncing rootfs content"
rsync --archive -H -A -X ${ROOTFS_PATH}/* ${IMG_MOUNTPOINT}
rsync --archive -H -A -X ${ROOTFS_PATH}/.[^.]* ${IMG_MOUNTPOINT}
sync

# Create stamp file
mkdir -p ${IMG_MOUNTPOINT}/var/lib/halium
touch ${IMG_MOUNTPOINT}/var/lib/halium/requires-lvm-resize

# umount the image
echo "umount root image"
umount ${IMG_MOUNTPOINT}

# clean up
vgchange -an aarchd

losetup -d ${DEVICE}

img2simg ${WORK_DIR}/userdata.raw ${WORK_DIR}/userdata.img
rm -f ${WORK_DIR}/userdata.raw

zip -r ${ZIP_NAME}.zip ${WORK_DIR}/userdata.img

echo "done."
