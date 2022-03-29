#!/usr/bin/env zsh
ln -s "${0:A:h}/zshrc" "${ZDOTDIR:-$HOME}/.zshrc"
ln -s "${0:A:h}/zshenv" "${ZDOTDIR:-$HOME}/.zshenv"

source "${ZDOTDIR:-$HOME}/.zshenv"
source "${ZDOTDIR:-$HOME}/.zshrc"

autoload -U compinit && compinit -i
