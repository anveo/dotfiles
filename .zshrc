# zmodload zsh/zprof

# https://superuser.com/a/583502/24703
if [ -n "$TMUX" ]; then
  if [ `uname` = 'Darwin' ]; then
    if [ -f /etc/profile ]; then
      PATH=""
      source /etc/profile
    fi
  fi
fi

export DOTFILES=$HOME/dotfiles

if [[ ! -d ~/.zplug ]];then
  git clone https://github.com/b4b4r07/zplug ~/.zplug
fi

source ~/.zplug/init.zsh

# Setup completion paths
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

# Add Docker completions if they exist
docker_completions="$HOME/.docker/completions"
if [[ -d "$docker_completions" ]]; then
  fpath=($docker_completions $fpath)
fi

# Initialize completions once after all paths are set
# Cache compinit to speed up startup (only rebuild once per day)
autoload -Uz compinit
if [[ -n ${HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Make sure to use double quotes for zplug

# zplug "robbyrussell/oh-my-zsh", use:"lib/*.zsh"
# zplug "lib/*", from:oh-my-zsh
zplug "plugins/copydir",  from:oh-my-zsh
zplug "plugins/copyfile", from:oh-my-zsh
zplug "plugins/encode64", from:oh-my-zsh
zplug "plugins/extract",  from:oh-my-zsh
zplug "plugins/fzf",      from:oh-my-zsh
zplug "plugins/nmap",     from:oh-my-zsh
zplug "plugins/urltools", from:oh-my-zsh

zplug "b4b4r07/enhancd", use:init.sh
zplug "chrissicool/zsh-256color"
zplug "mafredri/zsh-async", from:github, use:async.zsh
zplug "MichaelAquilina/zsh-autoswitch-virtualenv"
zplug "supercrabtree/k"
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
zplug "Aloxaf/fzf-tab"
zplug "agkozak/zsh-z"
zplug "zsh-users/zsh-history-substring-search", defer:3
zplug "zsh-users/zsh-syntax-highlighting", defer:2

# if [[ $OSTYPE = (linux)* ]]; then
  # zplug "plugins/archlinux",            from:oh-my-zsh, if:"(( $+commands[pacman] ))"
  # #zplug "plugins/debian",               from:oh-my-zsh
  # zplug "plugins/dnf",                  from:oh-my-zsh, if:"(( $+commands[dnf] ))"
  # #zplug "plugins/fedora",               from:oh-my-zsh
  # zplug "plugins/mock",                 from:oh-my-zsh, if:"(( $+commands[mock] ))"
  # #zplug "plugins/suse",                 from:oh-my-zsh
  # #zplug "plugins/ubuntu",               from:oh-my-zsh
# fi

# if [[ $OSTYPE = (darwin)* ]]; then
# # zplug "plugins/brew",                 from:oh-my-zsh, if:"(( $+commands[brew] ))"
# fi
if zplug check "zsh-users/zsh-autosuggestions"; then
  # This speeds up pasting w/ autosuggest
  # https://github.com/zsh-users/zsh-autosuggestions/issues/238
  pasteinit() {
    OLD_SELF_INSERT=${${(s.:.)widgets[self-insert]}[2,3]}
    zle -N self-insert url-quote-magic # I wonder if you'd need `.url-quote-magic`?
  }

  pastefinish() {
    zle -N self-insert $OLD_SELF_INSERT
  }

  zstyle :bracketed-paste-magic paste-init pasteinit
  zstyle :bracketed-paste-magic paste-finish pastefinish

  bindkey '^ ' autosuggest-accept
fi

zplug "mollifier/anyframe"
if zplug check "mollifier/anyframe"; then
    # expressly specify to use peco
    #zstyle ":anyframe:selector:" use peco
    # expressly specify to use percol
    #zstyle ":anyframe:selector:" use percol
    # expressly specify to use fzf-tmux
    #zstyle ":anyframe:selector:" use fzf-tmux
    # expressly specify to use fzf
    zstyle ":anyframe:selector:" use fzf

    # specify path and options for peco, percol, or fzf
    #zstyle ":anyframe:selector:peco:" command 'peco --no-ignore-case'
    #zstyle ":anyframe:selector:percol:" command 'percol --case-sensitive'
    #zstyle ":anyframe:selector:fzf-tmux:" command 'fzf-tmux --extended'
    #zstyle ":anyframe:selector:fzf:" command 'fzf --extended'
    #zstyle ":anyframe:selector:fzf:" command 'fzf'

    #bindkey '^@' anyframe-widget-cd-ghq-repository
    #bindkey '^r' anyframe-widget-put-history
fi

# spaceship-prompt
zplug "denysdovhan/spaceship-prompt", use:spaceship.zsh, from:github, as:theme

if zplug check "denysdovhan/spaceship-prompt"; then
  source $HOME/dotfiles/zsh/spaceship-prompt/sections/aws_vault.zsh
  # source $HOME/dotfiles/zsh/spaceship-prompt/sections/k8s.zsh
  source $HOME/dotfiles/zsh/spaceship-prompt/sections/op.zsh
  source $HOME/dotfiles/zsh/spaceship-prompt/sections/subshell.zsh
fi

if zplug check "b4b4r07/enhancd"; then
  ENHANCD_FILTER="fzf:peco:percol"
  ENHANCD_COMMAND="c"
fi

source $HOME/dotfiles/bash/aliases
source $HOME/dotfiles/bash/functions
source $HOME/dotfiles/bash/env
source $HOME/dotfiles/bash/paths

for file in $DOTFILES/shell/*.sh; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

setopt HIST_IGNORE_DUPS     # Ignore adjacent duplication command history list
setopt HIST_IGNORE_SPACE    # Don't store commands with a leading space into history
setopt INC_APPEND_HISTORY   # write history on each command
# setopt SHARE_HISTORY        # share history across sessions
setopt EXTENDED_HISTORY     # add more info
export HISTFILE=~/.zsh_history
export SAVEHIST=100000
export HISTSIZE=100000

# ignore that $EDITOR is vim and use emacs bindings
bindkey -e

# Put secret stuff in here
if [ -f ~/.localrc ]; then
  . ~/.localrc
fi

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Emacs style
# autoload -z edit-and-execute-command
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

# autoload edit-and-execute-command
# zle -N edit-and-execute-command
# bindkey '^Xe' edit-and-execute-command

export PATH="./bin:$PATH"

# remove dups, useful with subshells
export PATH
export PATH="$($HOME/dotfiles/scripts/consolidate-path)"

zplug load # --verbose

# uncomment zmodload on line 1 to use profiling
# zprof
