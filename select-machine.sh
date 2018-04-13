#!/usr/bin/env bash

machine() {

    # Set Script Root Directory Variable
    basedir="${BASH_SOURCE%/*}"
    if [[ ! -d "$basedir" ]]; then basedir="$PWD"; fi

    # Generate Choices
    echo "The following machine profiles were found; select one:" > /dev/stderr

    # set the prompt used by select, replacing "#?"
    PS3="Input Number or 'stop': "

    # allow the user to choose a file
    select foldername in "${basedir}/machines"/*; do
        # leave the loop if the user says 'stop'
        if [[ "$REPLY" == stop ]]; then 
            exit 1 
        fi

        # complain if no file was selected, and loop to ask again
        if [[ "$foldername" == "" ]]; then
            echo "'$REPLY' is not a valid number" > /dev/stderr
            continue
        fi

        # now we can return the selected folder
        echo "$foldername"
        break
    done
}