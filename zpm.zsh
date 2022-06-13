function _enum_exit_code() {
    (( ${#@} != 3 )) && print '$#@ != 3, quitting' && return 42
    local archive="${2}"
    local destination="${3}"
    case $1 in
        0) print -n "Extracted ${archive} -> ${destination:a}" ;;
        1) print -n "Destination folder exists, renaming: ${archive} -> ${destination:a}" ;;
        2) print -n "Destination file exists, renaming: ${archive} -> ${destination:a}" ;;
        3) print -n "Unknown error" ;;
        4) print -n "Wrong file type: ${archive}" ;;
        42) print -n "Could not find $archive)" ;;
        43) print -n "${destination:a} already exists" ;;
        44) print -n "Permission denied to write to dir: ${destination:a}" ;;
        45) print -n "Destination is a file: ${destination:a}" ;;
        46) print -n "Wrong number of input args given" ;;
        47) print -n "No archive given" ;;
        48) print -n "No destination given" ;;
    esac
}

function __extracter_wrapper() {
    local arc="$1"
    local destination explicit_extract_location
    local exit_code
    if [[ -n "$2" ]]; then
        local explicit_extract_location="${2}"
    fi
    __extracter "$arc" 1>&2
    exit_code=$?
    print -n $destination
    return $exit_code
}

# usage: __extracter $archive $destination
function __extracter() {
    [[ -z "$1" ]] && return 47
    local arc="${1:a}"
    local pwd="$PWD"

    # error handling:
    if [[ ! -f "$arc" ]]; then
        # Could not find arc
        return 42
    fi

    # we split the string backwards looking for the top most
    # existing folder and checking the perms on that
    if [[ -n ${explicit_extract_location:a} ]]; then
        local dest="${explicit_extract_location:a}"
    else
        local dest="$PWD"
    fi

    local dirs=(${(@s:/:)${dest}})
    local dir="${dest}"
    if [[ ${#dirs} -eq 0 ]]; then
        dirs=("/" ${dirs[@]})
    fi

    for ((i=${#dirs[@]}-1; i>=0; i--)); do
        if [[ -e "$dir" ]]; then
            if [[ -d "$dir" ]]; then
                if [[ ! -w "$dir" ]]; then
                    destination="$dir"
                    # Permission denied to create dir
                    return 44
                else
                    break
                fi
            elif [[ -f "$dir" ]]; then
                    destination="$dir"
                    return 45
            fi
        fi
        dir="${dir%/*}"
    done

    local end_folder
    local rename_output=false
    # if explicit_extract_location is a dir, we assume the user
    # wants to keep the original name, but move the file to that dir:
    if [[ -n "$explicit_extract_location" ]]; then
        if [[ -d "$explicit_extract_location" ]]; then
            end_folder="$explicit_extract_location"
            rename_output=false
        elif [[ "${explicit_extract_location: -1}" == "/" ]]; then
            rename_output=false
            end_folder="$explicit_extract_location"
        else
            rename_output=true
            end_folder="${explicit_extract_location:a}"
            end_folder="${end_folder%/*}"
        fi
    else
        rename_output=false
        end_folder="$pwd"
    fi

    # because we chpwd we need to store the abs path of end_folder
    end_folder="${end_folder:a}"

    local randstr="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)"
    local prelim_dir="${HOME}/$randstr"
    mkdir -p "$prelim_dir"
    cd "$prelim_dir"

    case "${arc:l}" in
        (*.tar.gz|*.tgz) (( $+commands[pigz] )) && { pigz -dc "$arc" | tar xv } || tar zxvf "$arc" ;;
        (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$arc" ;;
        (*.tar.xz|*.txz)
            tar --xz --help &> /dev/null \
            && tar --xz -xvf "$arc" \
            || xzcat "$arc" | tar xvf - ;;
        (*.tar.zma|*.tlz)
            tar --lzma --help &> /dev/null \
            && tar --lzma -xvf "$arc" \
            || lzcat "$arc" | tar xvf - ;;
        (*.tar.zst|*.tzst)
            tar --zstd --help &> /dev/null \
            && tar --zstd -xvf "$arc" \
            || zstdcat "$arc" | tar xvf - ;;
        (*.tar) tar xvf "$arc" ;;
        (tar.lz) (( $+commands[lzip] )) && tar xvf "$arc" ;;
        (*.gz) (( $+commands[pigz] )) && pigz -dk "$arc" || gunzip -k "$arc" ;;
        (*.bz2) bunzip2 "$arc" ;;
        (*.xz) unxz "$arc" ;;
        (*.lzma) unlzma "$arc" ;;
        (*.z) uncompress "$arc" ;;
        (*.zip|*.war|*.jar|*.sublime-package|*.ipsw|*.xpi|*.apk|*.aar|*.whl) unzip "$arc" ;;
        (*.rar) unrar x -ad "$arc" ;;
        (*.rpm) rpm2cpio "../$arc" | cpio --quiet -id ;;
        (*.7z) 7za x "$arc" ;;
        (*.deb)
            mkdir -p "control"
            mkdir -p "data"
            ar vx "../${arc}" > /dev/null
            cd control; tar xzvf ../control.tar.gz
            cd ../data; extract ../data.tar.*
            cd ..; rm *.tar.* debian-binary
            cd ..
        ;;
        (*.zst) unzstd "$arc" ;;
        (*)
            rmdir -p --ignore-fail-on-non-empty "$prelim_dir"
            cd "$pwd"
            return 4
        ;;
    esac

    # we are now in the prelim dir and can look at the files
    local all_files=(*(ND))

    local end_file_name
    local final_prelim_name
    if [[ ${#all_files[@]} -eq 1 ]]; then
        if [[ $rename_output == true ]]; then
            end_file_name="${explicit_extract_location##*/}"
        else
            end_file_name="${all_files}"
        fi
        final_prelim_name="$all_files"
    fi

    if [[ ${#all_files[@]} -gt 1 ]]; then
        print 1
        if [[ $rename_output == true ]]; then
            end_file_name="${explicit_extract_location##*/}"
        else
            end_file_name="${${arc:t}%%.*}"
        fi
        local randstr_two="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)"
        local prelim_dir_two="${HOME}/$randstr_two"
        mkdir -p "$prelim_dir_two"
        mv *(ND) "$prelim_dir_two"
        final_prelim_name="$prelim_dir_two"
    fi

    destination="${end_folder}/${end_file_name}"
    if [[ -e "$destination" ]]; then
        end_file_name+="-$randstr"
        local exit_code
        if [[ -d "$destination" ]]; then
            exit_code=1
        fi
        if [[ -f "$destination" ]]; then
            exit_code=2
        fi
    fi
    destination="${end_folder}/${end_file_name}"

    if [[ ! -d "${end_folder}" ]]; then
        _create_dirs_recursively "${end_folder}"
    fi

    mv $final_prelim_name "${end_folder}/${end_file_name}"
    rmdir "$prelim_dir"
    cd "$pwd"
    return ${exit_code:-0}
}

_create_dirs_recursively() {
    local location="${1:a}"
    # we check if subdirs were given
    typeset -a a=("${(@s:/:)location}") # @ modifier
    local folder
    local mypath=''
    for folder in ${a[@]}; do
        if [[ -e "$mypath" ]] && [[ -f "$mypath" ]]; then
            mypath+=-$randstr
        fi
        mypath+=/${folder}
    done
    if [[ ! -d "$mypath" ]]; then
        mkdir -p "$mypath"
    fi
}

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
        if [[ ! "$1" =~ '^(force|pull|reset|show|dirty)$' ]]; then
            print -l "Plugins must be put in $(_colorizer_abs_path ${ZDOTDIR:-$HOME}/.zshrc) to be loaded."\
            "Interactive usage: zpm <command> [<plugins>]\n"\
            "Commands:"\
            "  force  --  Hard reset repo and git pull"\
            "  pull   --  Do a git pull"\
            "  reset  --  Delete the repo and start anew"\
            "  dirty --  Show dirty repositories status"\
            "  show   --  List plugins"
            return 1
        fi
        local _zpm plg "_$1"
        shift
        for plg in "${@:-${_zplgs[@]}}"; do
            [[ ${@} ]] && _zpm="${_zplgs[(r)*/$plg]}" || _zpm="$plg"
            [[ -z "$_zpm" ]] && _ppn "" $plg 0 " is not an installed plugin" && continue || plg="$_zpm"
            (( ${+_show} )) && _ppn "" "$plg" 26 "➔  $(_colorizer_abs_path $plg)" && continue
            (( ${+_dirty} )) && (){ local _gitstatus="$(git -c color.ui=always -C ${plg} status --short 2> $_zpm_out)" && (( ${#_gitstatus} > 1 )) && _ppn "" "$plg" && print $_gitstatus; continue }
            (( ${+_reset} )) && { [[ "$plg" != "$ZPM" ]] && rm -rf $plg; continue }
            [[ ! -d "${plg}/.git" ]] && _ppn "\e[38;5;242mSkipping " "$plg" 27 "\e[38;5;242mNot a git repository.\e[0m" && continue
            (( ${+_force} )) && git -C "$plg" reset --hard HEAD > $_zpm_out 2>&1
            _pp "Updating " "$plg" 25 "… "
            git -C ${plg} pull 2> $_zpm_out ||\
            print "\e[31mFailed to update\e[0m"
        done
        (( ${+show} )) || exec $(which zsh)
    }
}

_eval_expr() {
    eval "${(P)1}" > $_zpm_out 2>&1 && return 0
    _ppn "\e[31mFailed \e[1m\e[34m$1\e[0m hook for " $remt_loc 0 ":\n${(P)1}\n\e[s"
    return 1
}

(( ${+ZPM_DEBUG} )) && {
    _zpm_out=/dev/tty
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
