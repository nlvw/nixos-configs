#!/usr/bin/env bash

# Set Script Root Directory Variable
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi

# Select Machine To Install AS
sMachine=$(bash "${sRoot}/select-machine.sh")
if [ ! $? == 0 ]; then
    echo "$sMachine"
    exit 1
fi

# Kickoff Install Script
bash "${sRoot}/machines/${sMachine}/install-os.sh"