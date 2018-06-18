#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Get Repository Root
if [ ! -v RepoRoot ]; then
    RepoRoot="$(dirname "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"
fi

# Install Additional Tools
echo "Installing 'git' if package is missing."
nix-env -i git

# Generate Default Configs
nixos-generate-config --root /mnt

# Get Desired Machine Configuration
echo "The following machine profiles were found; select one:"
select machine in "$RepoRoot"/machines/*/; do break; done

# Clone nixos-configs Repository To Installation
git -C /mnt/etc/nixos/ clone https://gitlab.com/Wolfereign/nixos-configs.git
chmod -R 700 /mnt/etc/nixos/nixos-configs

# Link configuration.nix
if [ -e "/mnt/etc/nixos/nixos-configs/machines/${machine}/configuration.nix" ]; then
    ln -rsf "/mnt/etc/nixos/nixos-configs/machines/${machine}/configuration.nix" /mnt/etc/nixos/configuration.nix
fi

# Link hardware_configuration.nix
if [ -e "/mnt/etc/nixos/nixos-configs/machines/${machine}/hardware_configuration.nix" ]; then
    ln -rsf "/mnt/etc/nixos/nixos-configs/machines/${machine}/hardware_configuration.nix" /mnt/etc/nixos/hardware_configuration.nix
fi
