type zsh-defer > /dev/null 2>&1 && local async=("zsh-defer")
type direnv > /dev/null 2>&1 && $async eval "$(direnv hook zsh)"
type pyenv > /dev/null 2>&1 && $async eval "$(pyenv init -)"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=cyan,underline' # custom style for autosuggestions

# - - - - - - - - - - - - - - - - - - - -
# - - - - - - CUSTOM PLUGINS- - - - - - -
# - - - - - - - - - - - - - - - - - - - -

zpm trbjo/zsh-multimedia if:'type transmission-remote'
zpm trbjo/zsh-wayland-utils if:'[[ $WAYLAND_DISPLAY ]]'

zpm trbjo/SublimeZshIntegration\
    where:'${XDG_CONFIG_HOME:-$HOME/.config}/sublime-text/Packages/SublimeZshIntegration'\
    if:'[[ -d /opt/sublime_text/ ]] && [[ $WAYLAND_DISPLAY ]]'

zpm trbjo/zsh-file-opener preload:'_ZSH_FILE_OPENER_CMD=u'

zpm trbjo/Neovim-config\
    if:'type nvim'\
    where:'${XDG_CONFIG_HOME:-$HOME/.config}/nvim'\
    postinstall:'nvim +PlugInstall +qall && printf "\e[6 q"'\
    nosource

zpm trbjo/omnisharp-config\
    if:'[[ -d /opt/sublime_text ]] && type dotnet'\
    where:'${HOME}/.omnisharp'\
    preload:'_dotnet_zsh_complete() { local completions=("$(dotnet complete "${words}")"); reply=( "${(ps:\n:)completions}" ) }; compctl -K _dotnet_zsh_complete dotnet'\
    nosource

zpm 'https://github.com/OmniSharp/omnisharp-roslyn/releases/download/v1.38.2/omnisharp-linux-x64.zip'\
    if:'[[ -d /opt/sublime_text ]] && type dotnet'\
    where:'${HOME}/.omnisharp-server'\
    postinstall:'chmod +x "${destination}/bin/mono" "${destination}/omnisharp/OmniSharp.exe"'\
    nosource

zpm trbjo/userchrome\
    if:'type firefox'\
    nosource

zpm tmux-plugins/tpm if:'type tmux && [[ ! -d "$HOME/.tmux" ]]' where:'$HOME/.tmux/plugins/tpm'\
    postinstall:'tmux run-shell "${HOME}/.tmux/plugins/tpm/bindings/install_plugins"'


# - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - ALIASES - - - - - - - -
# - - - - - - - - - - - - - - - - - - - -

if type pacman > /dev/null 2>&1; then
    if [[ $PopUp ]] && type subl > /dev/null 2>&1; then
        TRAPUSR2() {zle clear-screen ; subl=true fzf-clipman }
    else
        TRAPUSR2() { }
    fi
    # rehash path after pacman installation
    TRAPUSR1() { rehash; compinit -i }
fi

alias down='doas /usr/bin/networkctl down'
alias fdd='fd --no-ignore-vcs --hidden'
alias fix_whitespace="git ls-tree -r master --name-only | xargs sed -i 's/[ \t]*$//'"
alias g=git
alias LG='doas /usr/bin/LG_ultrafine_brightness'
alias nmctl='doas /usr/bin/networkctl'
alias ports='doas /usr/bin/ss -tunlp'
alias su='chmod o+rw $(tty); su -l'
alias up='doas /usr/bin/networkctl up'
alias vpn_restart='doas /usr/bin/systemctl restart openvpn.service'
alias vpn_start='doas /usr/bin/systemctl start openvpn.service'
alias vpn_stop='doas /usr/bin/systemctl stop openvpn.service'
alias restart_wifi='doas /usr/bin/systemctl restart iwd.service'
