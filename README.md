# zsh-plugin-manager

This is a super fast, super minimal, plugin manager written in less than 150 lines of code.

The focus is on simplicity and speed, and a good default user experience.

It supports asynchronous loading via the [romkatv/zsh-defer](https://github.com/romkatv/zsh-defer) plugin and automatically byte compiles your plugins.

## Installation
Just clone this repo and source the file. You can for example put this snippet in your `.zshrc` to source the file automatically and clone it, if it does not exist:

```zsh
ZPM="${HOME}/.zpm"

if [[ ! -d "${ZPM}" ]]; then
    print -n "\rInstalling \e[35m\e[3mzsh-plugin-manager\e[0m         … "
    command git clone --depth=1 https://github.com/trobjo/zsh-plugin-manager "${ZPM}" 2> /dev/null &&\
    print "\e[32m\e[3mSuccess\e[0m!"
    source "${ZPM}/zsh-plugin-manager.zsh"
    autoload -U compinit && compinit -i
else
    source "${ZPM}/zsh-plugin-manager.zsh"
fi

```

## Installing a plugin
Installing a plugin is as simple as declaring to zpm the url of the desired plugin. If the plugin is located on GitHub, you only need author and repo. Example:
```zsh
zpm zdharma-continuum/fast-syntax-highlighting
```
It also supports non git plugins in the form of archives and files. There is no update mechanism for these kinds of plugins though. Example:
```zsh
zpm 'https://github.com/junegunn/fzf/releases/download/0.29.0/fzf-0.29.0-linux_amd64.tar.gz'\
    where:'$HOME/.local/bin/fzf'\
    nosource
```
Please note that non-git plugins must be given an explicit location with the `where` keyword. More on keywords below.

## Asynchronous loading
Asynchronous plugin loading is faster than synchronous, but it might cause problems with some plugins. It is enabled by default, but can be turned off for a single plugin with `noasync`. To disable asynchronous loading altogether, simple declare the variable `ZPM_NOASYNC` before sourcing zpm.

## Keywords
If you need more fine grained control over the plugin, you can use additional keywords. Just add these keywords after the plugin name.

| Qualifier | Has value | Description |
|:-:|:-:|-|
|`if`|Yes|Loads the plugin iff the expression evaluates successfully|
|`defer`|Yes|Specifies options to `zsh-defer`. See [options](https://github.com/romkatv/zsh-defer/#usage)|
|`where`|Yes|Alternative plugin location. Mandatory for non-git plugins|
|`preload`|Yes|A shell expression run before the plugin is sourced. It is always run synchronously|
|`postload`|Yes|A shell expression run after the plugin is sourced. |
|`postinstall`|Yes|A shell expression that is run once after the installation.|
|`noasync`|No|Loads the plugin synchronously|
|`nosource`|No|Skips zcompiling and sourcing the plugin|

Examples:

```zsh
zpm trobjo/zsh-completions noasync
zpm romkatv/gitstatus
zpm trobjo/zsh-prompt-compact defer:'-1'\
    postload:'PROMPT_NO_SET_TITLE+=,_file_opener'\
    preload:'PROMPT_FANCY_ICONS='

zpm trobjo/zsh-multimedia if:'[[ $commands[transmission-remote] ]]'
zpm skywind3000/z.lua\
    if:'[[ $commands[lua] ]]'\
    preload:'_ZL_CMD=h'\
    postload:'_zlua_precmd() {(czmod --add "\${PWD:a}" &) }'

zpm 'https://raw.githubusercontent.com/trobjo/czmod-compiled/master/czmod' nosource\
    where:'$HOME/.local/bin/czmod'
```

## Interactive use
To use zpm in interactive mode, run the function `ZPM_LOADED` after the last plugin initialization. Now zpm switches to interactive mode, sporting four commands:

| Command | Description |
|:-:|-|
| force | Hard reset the repository and do a git pull |
| pull | Do a git pull |
| reset | Delete the repo. If the plugin is still in `.zshrc` it will be installed again |
| show | List plugins and their location |

Each of these commands take an optional list of plugins to perform the command on. If no plugins are listed after the command, the command will be run on all plugins currently loaded. If you have set compinit, you should be able to use tab completion.

For all commands, except `show` zpm will restart the shell with `exec zsh -l` to reload possible changes.

## Debug mode
If you have a plugin causing you trouble, or if you want to see how fast your plugins load, you can enable debugging by simply declaring the variable `ZPM_DEBUG` before sourcing zpm.
