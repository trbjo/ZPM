# set up the preliminary prompt while we wait for the plugins to initialize
[[ -o INTERACTIVE && -t 2 && ! $SSH_CONNECTION ]] && () {
    # typeset -g ZPM_DEBUG
    # typeset -g ZPM_NOASYNC
    (( ${+ZPM_DEBUG} )) && return
    PROMPT_EOL_MARK=
    print -Pn -- "\e]2;${PWD/$HOME/\~}\a"
    if (( ${+OLDPROMPT} )); then
        print -Pn -- "\e[?25l\n\n\e[1A\e[s${OLDPROMPT}\e[u"
        PROMPT=$'$OLDPROMPT\e[?25h'
    else
        print -Pn -- "\e[s\e[36m${${PWD/#$HOME/\~}//\//\e[39m\/\e[36m}\e[39m\n\e[35m❯\e[0m "
        PROMPT=$'\e[u\e[36m${PWD/$HOME/~}\n\e[35m❯\e[0m '
    fi
    (( ${+ZPM_NOASYNC} )) && print -n '\e[?25l\e[u'
}

(( ${+SSH_TTY} )) && export TERM="xterm-256color"
type go > /dev/null 2>&1 && export GOPATH="$HOME/go"

# Remove path duplicates
typeset -U PATH path fpath
typeset -aU path_elems

type npm > /dev/null 2>&1 && {
    export NPM_PACKAGES="${HOME}/.npm"
    path_elems+="$NPM_PACKAGES/bin"
}

type rustup > /dev/null 2>&1 && {
    local toolchain="$(rustup show active-toolchain)"
    if [[ -z "$toolchain" ]]; then
        rustup default nightly
        toolchain="$(rustup show active-toolchain)"
    fi
    path_elems+="$HOME/.rustup/toolchains/${toolchain/\ \(default\)/}/bin"
}

type dotnet > /dev/null 2>&1 && {
    path_elems+="$HOME/.dotnet/tools"
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
}

path=("$path_elems[@]" "$HOME/.local/bin" "$path[@]")
export PATH

