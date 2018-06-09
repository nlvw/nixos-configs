#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Create Lockdowned Folder
mkdir /mnt/etc/private
chmod -R 700 /mnt/etc/private

# Get Root Password
read -srp "Enter Desired Root Password: " rPass; echo
read -srp "Repeat Password: " rPass2; echo
[[ "$rPass" == "$rPass2" ]] || ( echo "Passwords did not match"; exit 1; )

# Get Admin/Main User Name
read -rp "Input Admin/Main User Name: " mUser; echo
: "${mUser:?"Missing User Name"}"

# Get Admin/Main User Password
read -srp "Enter Password for '$mUser': " mPass; echo
read -srp "Repeat Password: " mPass2; echo; echo
[[ "$mPass" == "$mPass2" ]] || ( echo "Passwords did not match"; exit 1; )

cat << EOF > /mnt/etc/nixos/private/users.nix
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
		extraGroups = [ "wheel" "networkmanager" ];
		uid = 1000;
		hashedPassword = "$(mkpasswd -m sha-512 "$mPass")";
	};
}
EOF