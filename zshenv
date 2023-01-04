# set up the fake prompt while we wait for the plugins to initialize
[[ -o INTERACTIVE && -t 2 ]] && {
    PROMPT_EOL_MARK=
    # typeset -g ZPM_NOASYNC
    # typeset -g ZPM_DEBUG

    # colors won't render correctly if the shell does not know about terminal capabilities
    (( ${+SSH_CONNECTION} )) && export TERM='xterm-256color' && _ssh="[${PROMPT_SSH_NAME:0:12}${${PROMPT_SSH_NAME[13,-1]}:+…}] "

    PROMPT_STR=$'${ZPM_DEBUG-\e8}'
    PROMPT_STR+='${SSH_CONNECTION:+%B[%b$PROMPT_SSH_NAME%B]%b }'
    [[ $PROMPT_PWD ]] && PROMPT_STR+=$PROMPT_PWD ||\
    PROMPT_STR+=%F{6}${${PWD/#$HOME/\~}//\//%F{fg_default_code}\/%F{6}}%F{fg_default_code}
    PROMPT_STR+='$PROMPT_READ_ONLY_DIR'
    PROMPT_STR+='${GITSTATUS:+%B%F{4}${GITSTATUS[7,${#GITSTATUS}]}'
    PROMPT_STR+='${PROMPT_WS_SEP:- }'
    PROMPT_STR+='%F{5}❯%f '
    typeset zero='%([BSUbfksu]|([FK]|){*})'
    (( ${#${(S%%)${(e)PROMPT_STR}//$~zero/}} > COLUMNS / 3 )) && PROMPT_WS_SEP=$'\n'

    local termpos
    print -Pn -- "\e7${(e)PROMPT_STR}\e]2;$_ssh${PWD/$HOME/\~}\a${ZPM_NOASYNC+\e8}\033[6n"
    # To avoid printing the prompt twice, we check if we are on the last line in the terminal.
    read -t 1 -s -d 'R' termpos
    if (( ${${termpos##*\[}%;*} == LINES )); then
        print -n '\e[?25l\r'
    fi
}

# Remove path duplicates
typeset -U fpath
export PATH
path=(
    ~/.dotnet/tools
    ~/.npm/bin
    ~/bin
    ~/.local/bin
    ~/.gem/ruby/*/bin(Nn[-1])
    ~/.opam/current/bin
    ~/.cabal/bin
    /opt/homebrew/bin
    /opt/homebrew/opt/coreutils/libexec/gnubin
    /opt/homebrew/sbin
    /usr/local/bin
    /usr/local/sbin
    /bin
    /usr/bin
    /usr/bin/*
    /usr/sbin
    /sbin
    /usr/games
    /usr/games/bin
)
path=( ${(u)^path:A}(N-/) )

type go > /dev/null 2>&1 && export GOPATH="$HOME/.local/share/go"
type npm > /dev/null 2>&1 && export NPM_PACKAGES="${HOME}/.npm"
type bat > /dev/null 2>&1 && export BAT_THEME=base16

type dotnet > /dev/null 2>&1 && {
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
}

type rustup > /dev/null 2>&1 && () {
    local tc=($HOME/.rustup/toolchains/*(ND))
    (( ${#tc} == 1 )) && path=("${tc}/bin" ${path[@]}) && return
    local toolchain="$(rustup show active-toolchain)"
    if [[ -z "$toolchain" ]]; then
        rustup default nightly
        toolchain="$(rustup show active-toolchain)"
    fi
    path=("$HOME/.rustup/toolchains/${toolchain/\ \(default\)/}/bin" ${path[@]})
}

[[ -z $EDITOR ]] && () {
    type nvim > /dev/null 2>&1 && export EDITOR=nvim && return
    type vim > /dev/null 2>&1 && export EDITOR=vim && return
    type emacs > /dev/null 2>&1 && export EDITOR='emacs -nw' && return
    type nano > /dev/null 2>&1 && export EDITOR=nano && return
}

[[ -z $VISUAL ]] && () {
    type nvim > /dev/null 2>&1 && export VISUAL=nvim && return
    type vim > /dev/null 2>&1 && export VISUAL=vim && return
    type emacs > /dev/null 2>&1 && export VISUAL='emacs -nw' && return
    type nano > /dev/null 2>&1 && export VISUAL=nano && return
}
