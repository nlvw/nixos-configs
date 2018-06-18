#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Get Repository Root
if [ ! -v RepoRoot ]; then
    RepoRoot="$(dirname "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"
fi

# Run Basic Format/Mounting For Boot Drive
. "${RepoRoot}/scripts/format-boot_disk-basic.sh"

# Mount BTRFS Raid/Pool
btrfs device scan
mkdir -p /mnt/butters
mount -o autodefrag -L butters /mnt/butters
