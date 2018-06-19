#!/usr/bin/env bash

# Error Handling
set -euo pipefail

# Install Needed Packages
echo "Installing 'mkpasswd, openssl' if packages are missing."
nix-env -i mkpasswd openssl

# Create Lockdowned Folder
mkdir /mnt/etc/nixos/private
chmod -R 700 /mnt/etc/nixos/private

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
        uid = 1000;
        createHome = true;
        home = "/home/${mUser}";
		hashedPassword = "$(mkpasswd -m sha-512 "$mPass")";
        extraGroups = [ "wheel" "networkmanager" "docker" ];
	};

    # Docker Media Library User
    users.users.curator = {
		isNormalUser = true;
		uid = 6846;
        createHome = false;
        #shell = /sbin/nologin;
		hashedPassword = "$(mkpasswd -m sha-512 $(openssl rand -base64 32))";
	};

}
EOF