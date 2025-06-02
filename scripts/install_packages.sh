#!/bin/bash

set -euo pipefail

VNDK=$1

if [ $VNDK -gt 29 ]; then
    pacman -Syyu pulseaudio-modules-droid-modern --needed --noconfirm
else
    pacman -Syyu pulseaudio-modules-droid-jb2q --needed --noconfirm
fi

pacman -Syyu aarchd-base adaptation-hybris-devtools adaptation-hybris-api${VNDK}-phone --needed --noconfirm
