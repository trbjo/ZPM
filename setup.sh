#!/usr/bin/env zsh

local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
local zshenv="${ZDOTDIR:-$HOME}/.zshenv"

[[ -f "$zshrc" ]] && print "$zshrc exists already, please move or delete it first" && exit 1
[[ -f "$zshenv" ]] && print "$zshenv exists already, please move or delete it first" && exit 1

ln -s "${0:A:h}/zshrc" "$zshrc"
ln -s "${0:A:h}/zshenv" "$zshenv"

source "${ZDOTDIR:-$HOME}/.zshenv"
source "${ZDOTDIR:-$HOME}/.zshrc"

autoload -U compinit && compinit -i
