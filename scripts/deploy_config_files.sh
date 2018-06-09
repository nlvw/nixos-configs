#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Generate Default Configs
nixos-generate-config --root /mnt

echo "The following machine profiles were found; select one:"
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

# Copy Repo To Installation
mkdir /mnt/etc/n
chmod -R 700 /mnt/etc/nixos/nixos-configs

# Link configuration.nix
if [ -e "../machines/${machine}/configuration.nix" ]; then
    cp -f "../machines/${machine}/configuration.nix" /mnt/etc/nixos/configuration.nix
fi

# Link hardware_configuration.nix
if [ -e "../machines/${machine}/hardware_configuration.nix" ]; then
    cp -f "../machines/${machine}/hardware_configuration.nix" /mnt/etc/nixos/hardware_configuration.nix
fi
