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
                 "  [Q]uit"
        unset ans
        until [[ ! -z $ans ]]; do
            read -sk reply
            case $reply in
                [Dd]) ans='Delete' ;;
                [Bb]) ans='Backup' ;;
                [Qq]) ans='Quit' ;;
            esac
        done
        if [[ $ans == "Quit" ]]; then
            exit
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
print -n "Do you want to switch to the trbjo branch? [y/N]"
until [[ ! -z $ans ]]; do
    read -sk reply
    case $reply in
        [Yy]) ans='Yes' ;;
        *) ans='No' ;;
    esac
done
print

if [[ $ans == "Yes" ]]; then
    git -C "${0:A:h}" switch trbjo
    if [[ ! -f "${HOME}/.config/htop/htoprc" ]]; then
        print -l \
        "# Beware! This file is rewritten by htop when settings are changed in the interface."\
        "# The parser is also very primitive, and not human-friendly."\
        "htop_version=3.1.2"\
        "config_reader_min_version=2"\
        "fields=0 48 2 46 47 49 1"\
        "hide_userland_threads=1"\
        "highlight_base_name=1"\
        "highlight_deleted_exe=1"\
        "tree_view=1"\
        "tree_view_always_by_pid=1"\
        "header_margin=0"\
        "show_cpu_temperature=1"\
        "hide_function_bar=2"\
        "header_layout=two_50_50"\
        "column_meters_0=AllCPUs4 Uptime LoadAverage"\
        "column_meter_modes_0=1 2 2"\
        "column_meters_1=Memory Swap Tasks Systemd"\
        "column_meter_modes_1=1 1 2 2" > "${HOME}/.config/htop/htoprc"
    fi
fi

autoload -U compinit && compinit -i
exec zsh
