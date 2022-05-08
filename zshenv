# set up the fake prompt while we wait for the plugins to initialize
[[ -o INTERACTIVE && -t 2 ]] && () {
    PROMPT_EOL_MARK=

    PROMPT_STR=%F{6}${${PWD/#$HOME/\~}//\//%F{fg_default_code}\/%F{6}}%{$reset_color%}%F{fg_default_code}
    PROMPT_STR+=$'$PROMPT_READ_ONLY_DIR'
    PROMPT_STR+='${GITSTATUS+%B${GITSTATUS_BLUE}%b%f}'
    typeset zero='%([BSUbfksu]|([FK]|){*})'
    (( ${#${(S%%)${(e)PROMPT_STR}//$~zero/}} > COLUMNS / 3 )) && PROMPT_STR+=$'\n' || PROMPT_STR+=' '
    PROMPT_STR+='${SSH_CONNECTION:+%B[%b$PROMPT_SSH_NAME%B]%b }'
    PROMPT_STR+='%F{5}❯%f '

    print -Pn -- "\e7${(e)PROMPT_STR}\e]2;${PWD/$HOME/\~}\a"
}

type go > /dev/null 2>&1 && export GOPATH="$HOME/.local/share/go"
type npm > /dev/null 2>&1 && export NPM_PACKAGES="${HOME}/.npm"

export XDG_CONFIG_HOME="${HOME}/.config"

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
