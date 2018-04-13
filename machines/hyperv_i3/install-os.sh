#!/usr/bin/env bash

# Set Script Root Directory and Name Variables
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi
sRootName=${sRoot##*/}

# Partition Drive (Keeps Nothing!!)
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
    # Reset Partion Table
    g # create new gpt partition table

    # Boot Partition
    n       # new partition
    3       # partition number
            # default start location
    +512M   # partition size
    t       # change part type
    1       # UEFI System

    # Swap Partition
    n       # new partition
    2       # partition number
            # default start location
    +8G     # partition size
    
    # Root Partition
    n       # new partition
    1       # partition number
            # default start location
            # default size (to end of disk)

    # Expert Mode Fixes?
    x
    f
    r

    # Write and Quit
    w
EOF

# Format Partitions
mkfs.vfat -F 32 -n boot /dev/sda1
mkswap -L swap /dev/sda2
mkfs.ext4 -L nixos /dev/sda3

# Mount Partitions
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Enable swap for installer
swapon /dev/disk/by-label/swap

# Generate Configs
nixos-generate-config --root /mnt

# Copy nixos-configs repo to root home
mkdir /mnt/root
cp -R "rRoot" /mnt/root/nixos-configs

# Link System Config Files
ln -sf "/mnt/root/nixos-configs/machines/${sRootName}/configuration.nix" /mnt/etc/nixos/configuration.nix
ln -sf "/mnt/root/nixos-configs/machines/${sRootName}/hardware-configuration.nix" /mnt/etc/nixos/hardware-configuration.nix

# Install System
nixos-install

# Set Root Password
#install prompts for this

# Finished!!
echo "All Done!! Shutdown, Remove Boot Media, and Enjoy!"
