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

if [ -d /usr/local/var/rbenv ]; then
  #export RBENV_ROOT=/usr/local/var/rbenv
  if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
fi
if [ -d $HOME/.rbenv ]; then
  #export RBENV_ROOT=$HOME/.rbenv/bin
  if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
fi

if [ `uname` == 'Darwin' ]; then
  if [ -f $(brew --prefix nvm)/nvm.sh ]; then
    export NVM_DIR=$HOME/.nvm
    source $(brew --prefix nvm)/nvm.sh
  fi
fi

source ~/.bash/prompt

export FZF_COMPLETION_TRIGGER='~~'
export FZF_CTRL_R_OPTS='--sort --exact'

# Setting ag as the default source for fzf
export FZF_DEFAULT_COMMAND='ag -g ""'

# To apply the command to CTRL-T as well
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

_fzf_compgen_path() {
  ag -g "" "$1"
}
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if [ -f ~/.localrc ]; then
  . ~/.localrc
fi
