#!/usr/bin/env bash

# Set Script Root Directory Variable
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi

# Source Machine Selection Function
. "$sRoot/select-machine.sh"

# Select Machine To Install AS
sMachine=$(machine)
if [ ! $? == 0 ]; then
    echo "$sMachine"
    exit 1
fi

# Kickoff Install Script
bash "${sRoot}/machines/${sMachine}/install-os.sh"