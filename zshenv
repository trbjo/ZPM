if (( ! ${+SSH_CONNECTION} )) && [[ -t 2 ]] && [[ $- == *i* ]] && [[ -f /usr/local/bin/goswitcher ]]; then
    /usr/local/bin/goswitcher &!
    goswitcher_pid=$!
fi

TRAPUSR1() {
    type -f compinit > /dev/null 2>&1 && compinit -i
    rehash
}

TRAPTERM() {
    kill -TERM ${goswitcher_pid:-0}
    exit 0
}

# set up the fake prompt while we wait for the plugins to initialize
[[ -o INTERACTIVE && -t 2 ]] && {
    PROMPT_EOL_MARK=
    # typeset -g ZPM_NOASYNC
    # typeset -g ZPM_DEBUG

    # colors won't render correctly if the shell does not know about terminal capabilities
    PROMPT_STR=$'${ZPM_DEBUG-\e8}'
    PROMPT_STR+='${SSH_CONNECTION:+%B[%b${PROMPT_SSH_NAME:-$HOST}%B]%b }'
    [[ $PROMPT_PWD ]] && PROMPT_STR+=$PROMPT_PWD ||\
    PROMPT_STR+=%F{6}${${PWD/#$HOME/\~}//\//%F{fg_default_code}\/%F{6}}%F{fg_default_code}
    PROMPT_STR+='$PROMPT_READ_ONLY_DIR'
    PROMPT_STR+='${GITSTATUS}'
    PROMPT_STR+='${PROMPT_WS_SEP:- }'
    PROMPT_STR+='%F{5}❯%f '
    typeset zero='%([BSUbfksu]|([FK]|){*})'
    (( ${#${(S%%)${(e)PROMPT_STR}//$~zero/}} > COLUMNS / 3 )) && PROMPT_WS_SEP=$'\n'

    local termpos
    print -Pn -- "\e7${(e)PROMPT_STR}\e]2;${PWD/$HOME/\~}\a${ZPM_NOASYNC+\e8}\033[6n"
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

() {
    local editor
    for editor in 'emacs -nw' 'nvim' 'vim' 'nano'; do
        if type "${editor%% *}" > /dev/null 2>&1; then
            [[ -z $EDITOR ]] && export EDITOR="$editor"
            [[ -z $VISUAL ]] && export VISUAL="$editor"
            return
        fi
    done
}

