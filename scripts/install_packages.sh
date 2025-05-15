#!/bin/bash

set -euo pipefail

VNDK=$1

pacman -Syyu aarchd-base adaptation-hybris-devtools adaptation-hybris-api${VNDK}-phone --needed --noconfirm
