#!/usr/bin/env bash

set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Set Script Root Directory and Name Variables
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi
sRootName=${sRoot##*/}

# Set Repository Root
p1="$(dirname "$sRoot")"
rRoot="$(dirname "$p1")"

### Get Information From User ###
hostname=$(dialog --stdout --inputbox "Enter hostname" 0 0) || exit 1
clear
: ${hostname:?"hostname cannot be empty"}

user=$(dialog --stdout --inputbox "Enter admin username" 0 0) || exit 1
clear
: ${user:?"user cannot be empty"}

password=$(dialog --stdout --passwordbox "Enter admin password" 0 0) || exit 1
clear
: ${password:?"password cannot be empty"}
password2=$(dialog --stdout --passwordbox "Enter admin password again" 0 0) || exit 1
clear
[[ "$password" == "$password2" ]] || ( echo "Passwords did not match"; exit 1; )

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)
device=$(dialog --stdout --menu "Select installtion disk" 0 0 0 ${devicelist}) || exit 1
clear

### Set up logging ###
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

### Setup the disk and partitions ###
swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
swap_end=$(( $swap_size + 954 + 1 ))MiB

# Partition Drive (Keeps Nothing!!)
printf "Paritioning Hard Drive!\n"
parted --script "${device}" \
        mklabel gpt \
        mkpart ESP fat32 1MiB 954MiB name 1 boot set 1 esp on \
        mkpart primary linux-swap 1GiB ${swap_end} name 2 swap \
        mkpart primary ext4 ${swap_end} 100% name 3 nixos

# Simple globbing was not enough as on one device I needed to match /dev/mmcblk0p1 
# but not /dev/mmcblk0boot1 while being able to match /dev/sda1 on other devices.
part_boot="$(ls ${device}* | grep -E "^${device}p?1$")"
part_swap="$(ls ${device}* | grep -E "^${device}p?2$")"
part_root="$(ls ${device}* | grep -E "^${device}p?3$")"

# Clean Partitions
printf "Cleaning Partitions!\n"
wipefs --all --force "${part_boot}"
wipefs --all --force "${part_swap}"
wipefs --all --force "${part_root}"

# Format Partitions
printf "Formatting Partitions!\n"
mkfs.vfat -F 32 -n boot "${part_boot}"
mkswap -L swap "${part_swap}"
mkfs.ext4 -F -L nixos "${part_root}"

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
