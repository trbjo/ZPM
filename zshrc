# source plugin manager
source "${${${(%):-%N}:A}%/*}/zpm.zsh"
PROMPT=${PROMPT_STR}

# - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - PLUGINS - - - - - - - -
# - - - - - - - - - - - - - - - - - - - -

# sets up zsh completion system, some keybindings, and some useful aliases
zpm trbjo/zsh-sensible-defaults

# Sets up the z command in a fast lua implementation
zpm skywind3000/z.lua if:'type lua'\
    preload:'_ZL_CMD=h'\
    postload:'_zlua_precmd() {czmod --add "${PWD:a}" &! }'&&\
zpm 'https://raw.githubusercontent.com/trbjo/czmod-compiled/master/czmod'\
    where:'$HOME/.local/bin/czmod'\
    nosource

zpm zsh-users/zsh-syntax-highlighting
zpm zsh-users/zsh-autosuggestions

# Adds functionality to buffer. Autopairing of quotes, etc.
zpm trbjo/zsh-goodies preload:'KEYTIMEOUT=1; setopt AUTO_PUSHD'

# Docker autocomplete
zpm 'https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/docker/_docker'\
    if:'type docker && ! type _docker'\
    postinstall:'autoload -U compinit; compinit -i'\
    where:'${ZPM}/completions/_docker'\
    preload:'
        zstyle ":completion:*:*:docker:*" option-stacking yes;
        zstyle ":completion:*:*:docker-*:*" option-stacking yes;'\
    nosource

if [[ "$(uname)" == "Linux" ]]; then
zpm 'https://github.com/junegunn/fzf/releases/download/0.29.0/fzf-0.29.0-linux_amd64.tar.gz'\
    if:'! type fzf'\
    where:'$HOME/.local/bin/fzf'\
    nosource
fi

zpm trbjo/zsh-fzf-functions

# Dependency of prompt
zpm romkatv/gitstatus
zpm trbjo/zsh-prompt-compact preload:"typeset -g __PROMPT_NEWLINE; TRAPWINCH() { zle && prompt_split_lines 2> /dev/null && { zle reset-prompt } }; EXTRA_SSH_ENV='git clone https://github.com/trbjo/ZPM ~/.ZPM && ~/.ZPM/setup.sh && exec zsh'"

# - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - SETOPTS - - - - - - - -
# - - - - - - - - - - - - - - - - - - - -

WORDCHARS=${WORDCHARS//[\/\.&=]}

setopt extendedglob             # Use Extended Globbing.
setopt autocd                   # Automatically Change Directory If A Directory Is Entered.
LISTMAX=999                     # Disable 'do you wish to see all %d possibilities'

# Completion Options.
setopt complete_in_word         # Complete From Both Ends Of A Word.
setopt always_to_end            # Move Cursor To The End Of A Completed Word.
setopt path_dirs                # Perform Path Search Even On Command Names With Slashes.
setopt auto_menu                # Show Completion Menu On A Successive Tab Press.
setopt auto_list                # Automatically List Choices On Ambiguous Completion.
setopt auto_param_slash         # If Completed Parameter Is A Directory, Add A Trailing Slash.
setopt no_complete_aliases

setopt auto_resume              # Attempt To Resume Existing Job Before Creating A New Process.
setopt no_beep                  # Don't beep
setopt no_bg_nice               # Don't frob with nicelevels
setopt no_flow_control          # Disable ^S, ^Q, ^\ for zsh

setopt appendhistory notify
unsetopt beep nomatch
setopt histignorespace

setopt hist_reduce_blanks       # remove unnecessary blanks
setopt bang_hist                # Treat The '!' Character Specially During Expansion.
setopt share_history            # Share History Between All Sessions.
setopt hist_expire_dups_first   # Expire A Duplicate Event First When Trimming History.
setopt hist_ignore_dups         # Do Not Record An Event That Was Just Recorded Again.
setopt hist_ignore_all_dups     # Delete An Old Recorded Event If A New Event Is A Duplicate.
setopt hist_find_no_dups        # Do Not Display A Previously Found Event.
setopt extended_history         # Show Timestamp In History.
setopt inc_append_history       # Write To The History File Immediately, Not When The Shell Exits.
setopt inc_append_history_time  # append command to history file immediately after execution

setopt interactive_comments     # allow comments in commands. Useful for postfixing a comment to a command
setopt prompt_subst             # allow prompt substitution

# History.
HISTFILE="${ZDOTDIR:-$HOME}/.zhistory"
HISTSIZE=10000
SAVEHIST=10000
HISTORY_IGNORE='([bf]g *|[bf]g|disown|cd ..|cd -)' # Don't add these to the history file.

# after this config, the user can use his own aliases in the file ~/.zshrc.local.zsh
if [[ -e "${ZDOTDIR:-$HOME}/.zshrc.local.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zshrc.local.zsh"
fi

ZPM_LOADED # initialize zpm interactive mode
