#!/usr/bin/env bash

#################################################################################################################
# Script Setup Tasks
#################################################################################################################

# Error Handling
set -uo pipefail

# Logging
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

# Set Script Root Directory and Name Variables
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi

#################################################################################################################
# Install Needed Setup Packages
#################################################################################################################
echo "Pulling Extra Needed Packages!  This may take a while."
nix-env -i git mkpasswd
clear


#################################################################################################################
# User Input
#################################################################################################################

# Get Desired Hostname
read -rp "Input Desired Hostname: " hName; echo
: "${hName:?"Missing hostname"}"

# Get Admin/Main User Name
read -rp "Input Admin/Main User Name: " mUser; echo
: "${mUser:?"Missing User Name"}"

# Get Admin/Main User Password
read -srp "Enter Password for '$mUser': " mPass; echo
read -srp "Repeat Password: " mPass2; echo; echo
[[ "$mPass" == "$mPass2" ]] || ( echo "Passwords did not match"; exit 1; )

# Get Root Password
read -srp "Enter Desired Root Password: " rPass; echo
read -srp "Repeat Password: " rPass2; echo
[[ "$rPass" == "$rPass2" ]] || ( echo "Passwords did not match"; exit 1; )

# Get Desired Machine Configuration
echo; echo; echo "The following machine profiles were found; select one:"
PS3="Input Number or 'stop': "
select machine in basic portland shuttle-ds81 testing zaku; do
    # leave the loop if the user says 'stop'
    if [[ "$REPLY" == stop ]]; then 
        exit 1 
    fi

    # complain if no file was selected, and loop to ask again
    if [[ "$machine" == "" ]]; then
        echo "'$REPLY' is not a valid number"
        continue
    fi

    # now we can return the selected folder
    echo "$machine"
    break
done

# Get Desired Installation Disk (Whole Disk wille be destroyed and then used!!!!)
echo; echo; echo
lsblk -dplx size -o name,size,type,mountpoint | grep -Ev "boot|rpmb|loop"
echo; echo "Please Select The Hardrive to Install To!"
select device in $(lsblk -dplnx size -o name | grep -Ev "boot|rpmb|loop"); do
	# leave the loop if the user says 'stop'
	if [[ "$REPLY" == stop ]]; then 
			exit 1 
	fi

	# complain if no file was selected, and loop to ask again
	if [[ "$device" == "" ]]; then
			echo "'$REPLY' is not a valid number" 
			continue
	fi

	# now we can return the selected folder
	echo "$device"
	break
done

#################################################################################################################
# Partition, Format, & Mount OS Disk
#################################################################################################################

### Setup the disk and partitions ###
swap_size=$(free --mebi | awk '/Mem:/ {print $2}')
swap_end="$(( $swap_size + 954 + 1 ))MiB"

# Partition Drive (Keeps Nothing!!)
printf "Paritioning Hard Drive!\n"
parted --script "${device}" \
        mklabel gpt \
        mkpart ESP fat32 1MiB 954MiB name 1 boot set 1 esp on \
        mkpart primary linux-swap 954MiB "${swap_end}" name 2 swap \
        mkpart primary ext4 "${swap_end}" 100% name 3 nixos

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

# Pause To Prevent Errors In Mounting
sleep 5s

# Mount Partitions
printf "Mounting Partitions!\n"
mount /dev/disk/by-label/nixos /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Enable swap for installer
swapon /dev/disk/by-label/swap

#################################################################################################################
# Setup Configuration Files
#################################################################################################################

# Generate Configs
nixos-generate-config --root /mnt

# Copy Repo To Installation
git -C /mnt/etc/nixos/ clone https://github.com/Wolfereign/nixos-configs.git
chmod -R 700 /mnt/etc/nixos/nixos-configs

# Link configuration.nix
if [ -e "/mnt/etc/nixos/nixos-configs/machines/${machine}/configuration.nix" ]; then
    ln -sf "/mnt/etc/nixos/nixos-configs/machines/${machine}/configuration.nix" /mnt/etc/nixos/configuration.nix
fi

# Link hardware_configuration.nix
if [ -e "/mnt/etc/nixos/nixos-configs/machines/${machine}/hardware_configuration.nix" ]; then
    ln -sf "/mnt/etc/nixos/nixos-configs/machines/${machine}/hardware_configuration.nix" /mnt/etc/nixos/hardware_configuration.nix
fi

# Create hostname.nix
cat << EOF > /mnt/etc/nixos/nixos-configs/private/hostname.nix
{ config, ... }:
{
	# Host Name
	networking.hostName = "$hName";
}
EOF

# Create users.nix
cat << EOF > /mnt/etc/nixos/nixos-configs/private/users.nix
{ config, ... }:
{
	# force user/group management to be immutable (this file)
	users.mutableUsers = false;

	# Root
	users.users.root = {
		hashedPassword = "$(mkpasswd -m sha-512 "$rPass")";
	};

	# Main user generated from bootstrap.sh
	users.users.${mUser} = {
		isNormalUser = true;
		description = "Main System User";
		extraGroups = [ "wheel" "networkmanager" ];
		uid = 1000;
		hashedPassword = "$(mkpasswd -m sha-512 "$mPass")";
	};
}
EOF

#################################################################################################################
# Install NixOS
#################################################################################################################

# Install System
echo "Installing NixOS!! This will take a while."
nixos-install

#################################################################################################################
# Post-Install Tasks
#################################################################################################################

# Download & Install My Dotfiles
echo "Downloading & Installing dotfiles for ${mUser}."
git -C "/mnt/home/${mUser}/" clone https://github.com/Wolfereign/.dotfiles.git
nixos-enter -c "chown -R '$mUser':users '/home/${mUser}/.dotfiles'"
nixos-enter -c "su '$mUser' -c 'bash ~/.dotfiles/bootstrap.sh'"

# Finished!!
echo; echo "All Done!! Shutdown, Remove Boot Media, and Enjoy!"
