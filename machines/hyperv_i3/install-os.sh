#!/usr/bin/env bash

# Set Script Root Directory and Name Variables
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi
sRootName=${sRoot##*/}

# Set Repository Root
p1="$(dirname "$sRoot")"
rRoot="$(dirname "$p1")"

# Partition Drive (Keeps Nothing!!)
printf "Paritioning Hard Drive!\n"
parted --script /dev/sda \
        mklabel gpt \
        mkpart ESP fat32 1MiB 1GiB name 1 boot set 1 esp on \
        mkpart primary linux-swap 1GiB 9GiB name 2 swap \
        mkpart primary ext4 9GiB 100% name 3 nixos

# Clean Partitions
printf "Cleaning Partitions!\n"
wipefs --all --force /dev/sda1
wipefs --all --force /dev/sda2
wipefs --all --force /dev/sda3

# Format Partitions
printf "Formatting Partitions!\n"
mkfs.vfat -F 32 -n boot /dev/sda1
mkswap -L swap /dev/sda2
mkfs.ext4 -F -L nixos /dev/sda3

# Mount Partitions
printf "Mounting Partitions!\n"
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Enable swap for installer
swapon /dev/disk/by-label/swap

# Generate Configs
nixos-generate-config --root /mnt

# Copy nixos-configs repo to root home
mkdir /mnt/root
cp -R "$rRoot" /mnt/root/nixos-configs

# Link System Config Files
ln -sf "/mnt/root/nixos-configs/machines/${sRootName}/configuration.nix" /mnt/etc/nixos/configuration.nix
ln -sf "/mnt/root/nixos-configs/machines/${sRootName}/hardware-configuration.nix" /mnt/etc/nixos/hardware-configuration.nix

# Install System
nixos-install

# Set Root Password
#install prompts for this

# Finished!!
echo "All Done!! Shutdown, Remove Boot Media, and Enjoy!"
