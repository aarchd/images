#!/bin/bash

set -euo pipefail

VNDK=$1

BASE_URL="https://ci.ubports.com/job/UBportsCommunityPortsJenkinsCI/job/ubports%252Fporting%252Fcommunity-ports%252Fjenkins-ci%252Fgeneric_arm64/job"

if [[ "$VNDK" == "28" ]]; then
    URL="$BASE_URL/main/lastSuccessfulBuild/artifact/halium_halium_arm64.tar.xz"
elif [[ "$VNDK" == "29" ]]; then
	URL="$BASE_URL/halium-10.0/lastSuccessfulBuild/artifact/halium_halium_arm64.tar.xz"
elif [[ "$VNDK" == "30" ]]; then
	URL="$BASE_URL/halium-11.0/lastSuccessfulBuild/artifact/halium_halium_arm64.tar.xz"
elif [[ "$VNDK" == "32" ]]; then
	URL="$BASE_URL/halium-12.0/lastSuccessfulBuild/artifact/halium_halium_arm64.tar.xz"
elif [[ "$VNDK" == "33" ]]; then
	URL="$BASE_URL/halium-13.0/lastSuccessfulBuild/artifact/halium_halium_arm64.tar.xz"
elif [[ "$VNDK" == "34" ]]; then
	URL="$BASE_URL/halium-14.0/lastSuccessfulBuild/artifact/halium_halium_arm64.tar.xz"
else
	echo "Invalid VNDK API: $VNDK"
	exit 1
fi

wget -q "$URL"
tar --strip-components=5 -xvf halium_halium_arm64.tar.xz system/var/lib/lxc/android/android-rootfs.img
install -Dm644 "android-rootfs.img" "build/$1/var/lib/lxc/android/android-rootfs.img"
