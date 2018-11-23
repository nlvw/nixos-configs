#!/usr/bin/env bash

# Pull Latest Configs from Git Repo
echo "Updating Configuration Repository!"
sudo git -C /etc/nixos/nixos-configs pull

# Update Server
echo "Updating NixOS!!"
sudo nixos-rebuild switch --upgrade

# Run Package Garbage Collection
echo "Deleting Unused Packages"
sudo nix-collect-garbage --delete-older-than 15
