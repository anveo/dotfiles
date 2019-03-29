# If not running interactively, don't do anything
# Important for ssh+svn support
# [ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# ... or force ignoredups and ignorespace
export HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

if [[ "${COLORTERM}" == "gnome-terminal" ]]; then
    export TERM="gnome-256color"
    unset COLORTERM
fi

source ~/.bash/env
source ~/.bash/config
source ~/.bash/aliases
source ~/.bash/completions
source ~/.bash/paths
source ~/.bash/functions

if [ -f /usr/local/etc/profile.d/z.sh ]; then
  . /usr/local/etc/profile.d/z.sh
else
  # https://github.com/rupa/z
  . "$HOME/dotfiles/bash/scripts/z.sh"
fi

if [ -d /usr/local/opt/asdf ]; then
  export NODEJS_CHECK_SIGNATURES=no
  source /usr/local/opt/asdf/asdf.sh
fi

source ~/.bash/prompt

# Use jj as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='jj'
export FZF_CTRL_R_OPTS='--sort --exact'

# Setting ag as the default source for fzf
export FZF_DEFAULT_COMMAND='ag -g ""'

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Options to fzf command
export FZF_COMPLETION_OPTS='--color fg:-1,bg:-1,hl:230,fg+:3,bg+:233,hl+:229 --color info:150,prompt:110,spinner:150,pointer:167,marker:174 -x'

alias preview="fzf --preview 'bat --color \"always\" {}'"
# add support for ctrl+o to open selected file in VS Code
export FZF_DEFAULT_OPTS="--bind='ctrl-o:execute(code {})+abort'"

# Use fd (https://github.com/sharkdp/fd) instead of the default find
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

#_fzf_compgen_path() {
#  ag -g "" "$1"
#}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# direnv
if [ -f $(brew --prefix direnv)/bin/direnv ]; then
  eval "$(direnv hook bash)"
fi

# Put secret stuff in here
if [ -f ~/.localrc ]; then
  . ~/.localrc
fi
