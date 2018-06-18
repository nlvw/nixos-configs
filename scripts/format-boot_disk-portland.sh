#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Get Directory of Running Script
ssroot="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run Basic Format/Mounting For Boot Drive
. "${ssroot}/format-boot_disk-basic.sh"

# Mount BTRFS Raid/Pool
btrfs device scan
mkdir -p /mnt/butters
mount -o autodefrag -L butters /mnt/butters
