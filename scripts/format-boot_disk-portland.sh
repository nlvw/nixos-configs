#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Run Basic Format/Mounting For Boot Drive
. ./format-boot_disk-basic.sh

# Mount BTRFS Raid/Pool
btrfs device scan
mount -o autodefrag -L butters /mnt/butters
