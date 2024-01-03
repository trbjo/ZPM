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

zpm trbjo/userchrome\
    if:'type firefox'\
    nosource

zpm tmux-plugins/tpm if:'type tmux && [[ ! -d "$HOME/.tmux" ]]' where:'$HOME/.tmux/plugins/tpm'\
    postinstall:'tmux run-shell "${HOME}/.tmux/plugins/tpm/bindings/install_plugins"'

zpm trbjo/contrib\
   where:'${HOME}/code/resights-contrib/resights-contrib.zsh'\
   if:'[[ $WAYLAND_DISPLAY ]]'

# - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - ALIASES - - - - - - - -
# - - - - - - - - - - - - - - - - - - - -

alias fdd='fd --no-ignore-vcs --hidden'
alias fix_whitespace="git ls-tree -r master --name-only | xargs sed -i 's/[ \t]*$//'"
alias LG='doas /usr/bin/LG_ultrafine_brightness'
alias ports='doas /usr/bin/ss -tunlp'
alias su='chmod o+rw $(tty); su -l'

alias restart_wifi='doas /usr/bin/systemctl restart iwd.service'
alias trust_wifi='echo -n "|$(grep -oE ([0-9a-f]{2}:){5}[0-9a-f]{2} /proc/net/arp)" >> ~/.config/environment.d/trusted_wifi.conf'


alias emil='noglob swaymsg -q -- output * scale 3'
alias normal='noglob swaymsg -q -- output * scale 2'
alias curl='curlie'

local become
[[ $UID == 0 ]] || become='doas'
alias sys="$become /usr/bin/systemctl"
alias mount="$become /usr/bin/mount"
alias net="$become /usr/bin/networkctl"

remove() { $become /usr/bin/umount $1 && $become /usr/bin/sync && print "usb is safe to remove"  || return 2 }

alias js='journalctl -n 200 --no-pager --follow --output cat --unit'
alias ju='journalctl -n 200 --no-pager --follow --output cat --user-unit'
alias wwifi='wifi systemctl --user restart networkonline.service'
alias bootlogs='journalctl -b --output cat --follow --since="$(uptime_iso.sh)"'

alias sablame='systemd-analyze blame'
alias sacritical='systemd-analyze critical-chain'
alias satime='systemd-analyze time'
alias sadump='systemd-analyze dump > systemd-dump.txt'
alias sasecurity='systemd-analyze security'

alias list-deps='systemctl list-dependencies'
alias failed-services='systemctl --failed'


alias Syu='doas pacman -Syu'
alias U='doas pacman -U'
alias Sy='doas pacman -Sy'
alias S='doas pacman -S'
alias Ss="pacman -Ss"
alias Rsn='doas pacman -Rsn'
alias Rns='doas pacman -Rsn'
alias Rdd='doas pacman -Rdd'
alias Qs='pacman -Qs'
# list packages owned by
alias Qo='pacman -Qo'
alias Qqs='pacman -Qqs'
alias Qq='pacman -Qq'

alias Qtdq='doas pacman -Rsn $(pacman -Qtdq)'

# strips the dollar sign when pasting from the internet
alias \$=''

# allows pasting from the internet
alias '#'=doas

# Git aliases
alias glo="git log --date=format:'%a %d %b %H.%M' --pretty=format:'%Cred%h %Cgreen%cd %C(blue)%an%Creset%Creset ●%d%Creset %s' --abbrev-commit"
alias gs='git status --porcelain --short'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gb='git branch'
alias gd='git diff'
alias ga='git add'
alias gap='git add -p'
alias gl='git log'
alias gcam='git commit -am'
alias gcm='git commit -m'
alias gpull='git pull --rebase'
alias gdn='git diff --name-only'
alias push='git push'
alias pushorigin='git push --set-upstream origin $(git branch --show-current)'
alias pull='git pull --rebase'

# Easy redirect
alias -g silent="> /dev/null 2>&1"
alias -g noerr="2> /dev/null"
alias -g onerr="1> /dev/null"
alias -g stdboth="2>&1"

if type rg > /dev/null 2>&1; then
    # grep for ipv4 addresses
    ipv4addrs() { rg --pcre2 '\b(?<!\.)(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?!\.)\b' }

    alias rgg="noglob rg --no-ignore-vcs --hidden --glob "!.zhistory""
    alias rg="noglob rg --glob "!.zhistory""
    alias rgf="noglob rg --fixed-strings --glob "!.zhistory""
    alias -g G=" |& rg "
    alias -g GG=" |& rg"
    alias -g GF=" |& rg --fixed-strings --"
    alias -g HL=" |& rg -C 9999999999999999 --"
else
    alias -g G=' |& grep --color=auto'
fi

if type eza > /dev/null 2>&1; then
    alias e='eza --group-directories-first'
    alias esort='eza --sort=oldest --long --git'
    alias ee='eza --group-directories-first --long --git'
    alias etree='eza --group-directories-first --long --git --tree'
    alias ea='eza --group-directories-first --long --git --all'
else
    alias e='ls --color=auto --group-directories-first'
    alias esort='ls --color=auto -lt --human-readable'
    alias ee='ls --color=auto --no-group --group-directories-first -l --human-readable'
    alias ea='ls --color=auto --group-directories-first --all --human-readable'
fi

countsource() {
    for extension in $(fd . -t f | rg -o '\.[a-zA-Z]+$' | sort | uniq | cut -c 2-); do
        printf "%-8s\t%s" "$extension"
        fd -t f -e $extension -0 | xargs -0 wc -l --total=only
    done | sort
}
# ffmpeg -i The.Julekalender.Afsnit.1-12.DiVX.DVDRip-RDK.avi -strict -2 OUTPUT.mp4

prepare_chromecast_audio() {
    local source="$1"
    local basename="${source%.*}"
    local target="${basename}.mp4"
    print "converting $source -> $target for sound"
    ffmpeg -i "$source" -map 0:v:0 -c:v copy -map 0:a:0 -map 0:a:0 -c:a:0 aac -ac:a:0 2 -b:a:0 192k -c:a:1 copy "$target"
}
