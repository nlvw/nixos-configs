#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Partition, Format, & Mount OS Disk
read -p "Do you want to format and mount the BOOT disk? This will erase the disk. (y/n) " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	select fbd in ./scripts/format-boot-disk-*.sh
	. $fbd
else
	echo "Skipping Partitioning/Mounting"
	echo "Script is proceeding with the assuption that /mnt is fully configured!!"
fi

# Custom or Default Deployment?
read -p "Do you want to use the configuration git repository? (y/n) " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	# Deploy Configuration Files
	. ./scripts/deploy-config-files.sh

	# Generate users.nix (if custom config files were deployed)
	echo "Select users.nix to generate."
	select usrnix in ./scripts/generate-users-*.sh
	. $usrnix

	# Install System
	echo "Installing NixOS!! This will take a while."
	nixos-install --no-root-passwd

	# Finished!!
	echo; echo "All Done!! Shutdown, Remove Boot Media, and Enjoy!"
else
	# Generate Default Configs
	nixos-generate-config --root /mnt

	# Install System
	echo "Do you want to format and mount the BOOT disk? This will erase the disk."
	select yn in "Yes" "No"
	case $yn in
		Yes ) nixos-install; echo; echo "All Done!! Shutdown, Remove Boot Media, and Enjoy!";;
		No ) echo "run 'nixos-install' when you are ready.";;
	esac
fi
