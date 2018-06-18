#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Get Directory of Running Script
sroot="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Partition, Format, & Mount OS Disk
read -p "Do you want to format and mount the BOOT disk? This will erase the disk. (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	select fbd in "${sroot}/scripts/format-boot_disk-*.sh"
	. "$fbd"
else
	echo "Skipping Partitioning/Mounting"
	echo "Script is proceeding with the assuption that /mnt is fully configured!!"
fi

# Custom or Default Deployment?
read -p "Do you want to use the configuration git repository? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	# Deploy Configuration Files
	. "${sroot}/scripts/deploy-config_files.sh"

	# Generate users.nix (if custom config files were deployed)
	echo "Select users.nix to generate."
	select usrnix in "${sroot}/scripts/generate-users-*.sh"
	. "$usrnix"

	# Install System
	echo "Installing NixOS!! This will take a while."
	nixos-install --no-root-passwd

	# Finished!!
	echo; echo "All Done!! Shutdown, Remove Boot Media, and Enjoy!"
else
	# Generate Default Configs
	echo "Generating default config files at /mnt/etc/nixos/"
	nixos-generate-config --root /mnt

	# Review/Edit configuration.nix
	read -p "Do you want to review/edit configuration.nix? (y/n) " -n 1 -r
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		vim /mnt/etc/nixos/configuration.nix
	fi

	# Review/Edit hardware_configuration.nix
	read -p "Do you want to review/edit hardware_configuration.nix? (y/n) " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		vim /mnt/etc/nixos/hardware_configuration.nix
	fi

	# Install System
	echo "Installing NixOS!! This will take a while."
	nixos-install 
fi
