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

# store multiline commands in a single history entry
shopt -s cmdhist

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

source $HOME/dotfiles/bash/env
source $HOME/dotfiles/bash/config
source $HOME/dotfiles/bash/aliases
source $HOME/dotfiles/bash/completions
source $HOME/dotfiles/bash/paths
source $HOME/dotfiles/bash/functions
source $HOME/dotfiles/bash/prompt

# source $HOME/dotfiles/shell/autojump.sh
# source $HOME/dotfiles/shell/direnv.sh
source $HOME/dotfiles/shell/adobe.sh
source $HOME/dotfiles/shell/fzf.sh
source $HOME/dotfiles/shell/nvm.sh
source $HOME/dotfiles/shell/rbenv.sh
source $HOME/dotfiles/shell/z.sh

# Put secret stuff in here
if [ -f ~/.localrc ]; then
  . ~/.localrc
fi
