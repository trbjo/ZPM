_zpm_install() {
    _pp "\r\033[0J\033[?25hInstalling " "$destination" ${ZPM_DEBUG+0}${ZPM_DEBUG-26} " … ${ZPM_DEBUG+\n}"
    [[ "$remt_loc" =~ ^[-a-zA-Z_0-9]+/[-\.a-zA-Z_0-9]+$ ]] &&\
        local pull_url="https://github.com/${remt_loc}"
    git clone --depth=1 "${pull_url:-$remt_loc}" "${destination}" > $_zpm_out 2>&1 && return 0
    [[ ! "$remt_loc" =~ ^https?://.+$ ]] && print "Invalid URL format: $remt_loc" && return 1
    [[ -z "$where" ]] && print "Non git plugins must have an explicit location set" && return 1
    local filename="$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir')/${remt_loc##*/}"
    curl --location "$remt_loc" --output "$filename" > $_zpm_out 2>&1 || return 1
    if [[ "${filename:e}" == "" ]]; then
        [[ ! -d "${destination%/*}" ]] && mkdir -p "${destination%/*}" > $_zpm_out 2>&1
        mv "${filename}" "${destination}" && [[ -f "${destination}" ]] && chmod +x "${(e)where}"
    else
        __extracter_wrapper "${filename}" "${destination}" 2> $_zpm_out 1> /dev/null
        local exit_code="$?"
        print $(_enum_exit_code $exit_code "${filename}" "${destination}") > $_zpm_out 2>&1
    fi
    rm -rf "${filename%/*}"
    return ${exit_code:-0}
}

zpm${ZPM_DEBUG+_debug}() {
    local part
    local -r remt_loc="${1/%\//}"
    for part in "${@:2}"; do
        local key="${part%%:*}"
        [[ $key == 'if' ]] && { eval "${part:(( ${#key} + 1))}" > /dev/null 2>&1 || return 1 } ||\
        local -r $key="${part:(( ${#key} + 1))}"
    done
    local destination="${(e)where:-${ZPM}/${${remt_loc%/*}##*/}/${remt_loc##*/}}"
    (( ${+preload} )) && { _eval_expr preload || return 1 }
    if [[ ! -e "${destination}" ]]; then
        if _zpm_install && _eval_expr postinstall; then
            print "\e[32mSuccess\e[0m!\033[s"
        else
            rm -rf "$destination"
            print "\e[31mFailed installation\e[0m, skipping plugin…"
            return 1
        fi
    fi
    (( ! ${+nosource} )) && {
        local filename="${destination}/${remt_loc##*/}"
        { [[ -f "${filename}.zsh" ]] && filename+=".zsh" } ||\
        { [[ -f "${filename}.plugin.zsh" ]] && filename+=".plugin.zsh" } ||\
        { _ppn "No file to source for " $remt_loc && return 1 }
        { [[ "${filename}" -nt "${filename}.zwc" ]] ||\
        [[ ! -f "${filename}.zwc" ]] && zcompile "${filename}" } &!
        (( ! ${+ZPM_NOASYNC} )) && (( ! ${+noasync} )) && local async=("zsh-defer" "${${(@s: :)defer}[@]}")
        $async sourcer_and_postload "$filename" "$remt_loc" $postload
    }
    _zplgs+="${destination}"
    (( ! ${+ZPM_DEBUG} )) || flatstring="${async:+${(@j. .)async:#} }${nosource+no}source"
}

sourcer_and_postload() {
    if (( $#@ == 3 )); then
        local -r filename="$1" remt_loc="$2" postload="$3"
        set --
        source "$filename" > $_zpm_out 2>&1
        _eval_expr postload
    else
        local filename="$1"
        set --
        source "$filename" > $_zpm_out 2>&1
    fi
}

_pp() { print -n "$1\e[35m\e[3m${(r:${3}:: :)${2##*/}}\e[0m${4}" }
_ppn() { print "$1\e[35m\e[3m${(r:${3}:: :)${2##*/}}\e[0m${4}" }

ZPM_LOADED() {
    print -n '\e[?25h'
    unfunction ZPM_LOADED
    zpm() {
        if [[ ! "$1" =~ '^(force|pull|reset|show)$' ]]; then
            print -l "Plugins must be put in $(_colorizer_abs_path ${ZDOTDIR:-$HOME}/.zshrc) to be loaded."\
            "Interactive usage: zpm <command> [<plugins>]\n"\
            "Commands:"\
            "  force  --  Hard reset repo and git pull"\
            "  pull   --  Do a git pull"\
            "  reset  --  Delete the repo and start anew"\
            "  show   --  List plugins"
            return 1
        fi
        local _zpm plg $1
        shift
        for plg in "${@:-${_zplgs[@]}}"; do
            [[ ${@} ]] && _zpm="${_zplgs[(r)*/$plg]}" || _zpm="$plg"
            [[ -z "$_zpm" ]] && _ppn "" $plg 0 " is not an installed plugin" && continue || plg="$_zpm"
            (( ${+show} )) && _ppn "" "$plg" 26 "➔  $(_colorizer_abs_path $plg)" && continue
            (( ${+reset} )) && { [[ "$plg" != "$ZPM" ]] && rm -rf $plg; continue }
            [[ ! -d "${plg}/.git" ]] && _ppn "\e[38;5;242mSkipping " "$plg" 27 "\e[38;5;242mIs not a git repo.\e[0m" && continue
            (( ${+force} )) && git -C "$plg" reset --hard HEAD > $_zpm_out 2>&1
            _pp "Updating " "$plg" 25 "… "
            git -C ${plg} pull 2> $_zpm_out ||\
            print "\e[31mFailed to update\e[0m"
        done
        (( ${+show} )) || exec $(which zsh)
    }
}

_eval_expr() {
    eval "${(P)1}" > $_zpm_out 2>&1 && return 0
    _ppn "\e[31mFailed \e[1m\e[34m$1\e[0m hook for " $remt_loc 0 ":\n${(P)1}"
    return 1
}

(( ${+ZPM_DEBUG} )) && {
    _zpm_out=/dev/stdout
    typeset -a _zplgs_remote
    zmodload zsh/datetime
    zpm() {
        (($_zplgs_remote[(Ie)$1])) && _ppn "\e[31mDuplicate plugin: " $1 && return 1
        local part start end flatstring
        for part in "${@:2}"; do
            [[ ! "${part%%:*}" =~ '^(if|defer|where|noasync|nosource|preload|postload|postinstall)$' ]] &&\
            _ppn "\e[31mInvalid key\e[0m: '\e[3m${part}\e[0m'. Skipping " ${1} && return 1
        done
        strftime -s start  %s%3. $epochtime
        zpm_debug "$@" &&\
        _zplgs_remote+="$1" &&\
        strftime -s end  %s%3. $epochtime &&\
        _ppn "\r$flatstring " "${1}" $((40 - ${#flatstring})) \
        " … took ${(l:4:: :)$((end - start))} ms"
    }
} || _zpm_out=/dev/null

typeset -gxr ZPM="${0:A:h}"
typeset -a _zplgs=($ZPM)
fpath+=("${ZPM}/completions/")
{ [[ "${0:A}" -nt "${0:A}.zwc" ]] ||\
[[ ! -f "${0:A}.zwc" ]] && zcompile "${0:A}" } &!
(( ! ${+ZPM_NOASYNC} )) && zpm 'romkatv/zsh-defer' noasync
zpm 'trbjo/zsh-common-functions' noasync
