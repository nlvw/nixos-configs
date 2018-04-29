#!/usr/bin/env bash

#################################################################################################################
# Script Setup Tasks
#################################################################################################################

# Error Handling
set -uo pipefail
#trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Logging
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

# Set Script Root Directory and Name Variables
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi

#################################################################################################################
# User Input
#################################################################################################################

# Get Desired Hostname
read -rp "Desired Hostname: " hName; echo
: "${hName:?"Missing hostname"}"

# Get Admin/Main User Name
read -rp "Admin/Main User Name: " mUser; echo
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
select machine in "${sRoot}/machines"/*; do
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
# Install NixOS
#################################################################################################################

# Generate Configs
nixos-generate-config --root /mnt

# Copy Machine Configs
if [ -e "${machine}/configuration.nix" ]; then
    yes | cp -f "${machine}/configuration.nix" /mnt/etc/nixos/configuration.nix
fi

if [ -e "${machine}/hardware_configuration.nix" ]; then
    yes | cp -f "${machine}/hardware_configuration.nix" /mnt/etc/nixos/hardware_configuration.nix
fi

# Set User Defined Information
sed -i "s/hName/${hName}/g" /mnt/etc/nixos/configuration.nix
sed -i "s/mUser/${mUser}/g" /mnt/etc/nixos/configuration.nix

# Install System
nixos-install --no-root-passwd

#################################################################################################################
# Post-Install Tasks
#################################################################################################################

# Set Passwords
nixos-enter -c "echo '$mUser:$mPass' | chpasswd"
nixos-enter -c "echo 'root:$rPass' | chpasswd"

# Download & Install My Dotfiles
nixos-enter -c "su '$mUser' -c 'git -C ~/ clone https://github.com/Wolfereign/.dotfiles.git'"
nixos-enter -c "su '$mUser' -c 'bash ~/.dotfiles/bootstrap.sh'"

# Finished!!
echo; echo "All Done!! Shutdown, Remove Boot Media, and Enjoy!"
