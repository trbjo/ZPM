#!/usr/bin/env zsh

local -a files=("zshrc" "zshenv")
local -a files_to_source
local filename file ans reply file_to_source
local location="${ZDOTDIR:-$HOME}"

for filename in $files; do
    file="${location}/.${filename}"
    if [[ -f "$file" ]]; then
        print -l "$file exists, want do you want to do?"\
                 "  [D]elete original"\
                 "  [B]ackup original"\
                 "  [S]kip this file"\
                 "  [Q]uit"
        unset ans
        until [[ ! -z $ans ]]; do
            read -sk reply
            case $reply in
                [Dd]) ans='Delete' ;;
                [Bb]) ans='Backup' ;;
                [Qq]) ans='Quit' ;;
                [Ss]) ans='Skip' ;;
            esac
        done
        if [[ $ans == "Quit" ]]; then
            exit
        elif [[ $ans == "Skip" ]]; then
            continue
        elif [[ $ans == "Delete" ]]; then
            rm "$file"
        elif [[ $ans == "Backup" ]]; then
            mv "$file" "${file}.bak"
            print "Saved ${file} as ${file}.bak"
        fi
    fi
    ln -s "${0:A:h}/$filename" "$file"
    files_to_source+="$file"
done

unset ans
print "Do you want to switch to the trbjo branch? [y/N]"
until [[ ! -z $ans ]]; do
    read -sk reply
    case $reply in
        [Yy]) ans='Yes' ;;
        *) ans='No' ;;
    esac
done

if [[ $ans == "Yes" ]]; then
    git -C "${0:A:h}" switch trbjo
fi

for file_to_source in $files_to_source; do
    source "$file_to_source"
done

autoload -U compinit && compinit -i
