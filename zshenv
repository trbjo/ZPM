# set up the fake prompt while we wait for the plugins to initialize
[[ -o INTERACTIVE && -t 2 ]] && () {
    PROMPT_EOL_MARK=
    if (( ${+OLDPROMPT} )); then
        print -Pn -- "\e[?25l\n\n\e[1A\e7${OLDPROMPT}\e8\e]2;$_ssh${PWD/$HOME/\~}\a"
    else
        print -Pn -- "\e7\e[36m${${PWD/#$HOME/\~}//\//\e[39m\/\e[36m}${_read_only_dir:+\e[38;5;18m$_read_only_dir}\e[39m\n${SSH_CONNECTION:+%B[%b$PROMPT_SSH_NAME%B]%b }\e[35m❯\e[0m \e]2;$_ssh${PWD/$HOME/\~}\a"
    fi
}

type go > /dev/null 2>&1 && export GOPATH="$HOME/.local/share/go"
type npm > /dev/null 2>&1 && export NPM_PACKAGES="${HOME}/.npm"

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
    /usr/sbin
    /sbin
    /usr/games
    /usr/games/bin
)

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

path=( ${(u)^path:A}(N-/) )
