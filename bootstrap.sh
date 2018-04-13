#!/usr/bin/env bash

# Set Script Root Directory Variable
sRoot="${BASH_SOURCE%/*}"
if [[ ! -d "$sRoot" ]]; then sRoot="$PWD"; fi

# Include Machine Selector Fucntion Script
. "$sRoot/select-machine.sh"

