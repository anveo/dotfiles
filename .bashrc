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

# A DOTFILES already in the environment wins, as in .zshrc.
export DOTFILES=${DOTFILES:-$HOME/dotfiles}

source $DOTFILES/bash/env
source $DOTFILES/bash/config
source $DOTFILES/bash/aliases
source $DOTFILES/bash/completions
source $DOTFILES/bash/paths
source $DOTFILES/bash/functions
source $DOTFILES/bash/prompt

# source $DOTFILES/shell/direnv.sh
source $DOTFILES/shell/adobe.sh
source $DOTFILES/shell/fzf.sh
# source $DOTFILES/shell/nvm.sh
source $DOTFILES/shell/fnm.sh
source $DOTFILES/shell/rbenv.sh
source $DOTFILES/shell/uv.sh
source $DOTFILES/shell/zoxide.sh

# Put secret stuff in here
if [ -f ~/.localrc ]; then
  . ~/.localrc
fi

