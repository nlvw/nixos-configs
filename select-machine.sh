#!/usr/bin/env bash

machine() {

    shopt -s extglob nullglob

    basedir="$(dirname "$0")/machines"

    # You may omit the following subdirectories
    # the syntax is that of extended globs, e.g.,
    # omitdir="cmmdm|not_this_+([[:digit:]])|keep_away*"
    # If you don't want to omit any subdirectories, leave empty: omitdir=
    omitdir=

    # Create array
    if [[ -z $omitdir ]]; then
    cdarray=( "$basedir"/*/ )
    else
    cdarray=( "$basedir"/!($omitdir)/ )
    fi

    # remove leading basedir:
    cdarray=( "${cdarray[@]#"$basedir/"}" )

    # remove trailing backslash and insert Exit choice
    cdarray=( Exit "${cdarray[@]%/}" )

    # At this point you have a nice array cdarray, indexed from 0 (for Exit)
    # that contains Exit and all the subdirectories of $basedir
    # (except the omitted ones)
    # You should check that you have at least one directory in there:
    if ((${#cdarray[@]}<=1)); then
        printf 'No subdirectories found. Exiting.\n'
        exit 1
    fi

    # Display the menu:
    printf 'Please choose from the following. Enter 0 to exit.\n'
    for i in "${!cdarray[@]}"; do
        printf '   %d %s\n' "$i" "${cdarray[i]}"
    done
    printf '\n'

    # Now wait for user input
    while true; do
        read -e -r -p 'Your choice: ' choice
        # Check that user's choice is a valid number
        if [[ $choice = +([[:digit:]]) ]]; then
            # Force the number to be interpreted in radix 10
            ((choice=10#$choice))
            # Check that choice is a valid choice
            ((choice<${#cdarray[@]})) && break
        fi
        printf 'Invalid choice, please start again.\n'
    done

    # At this point, you're sure the variable choice contains
    # a valid choice.
    if ((choice==0)); then
        printf 'Good bye.\n'
        exit 1
    fi

    # Now you can work with subdirectory:
    return "${cdarray[choice]}"
}