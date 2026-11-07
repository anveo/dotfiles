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
export XDG_CONFIG_HOME="$HOME/.config"

# Put Homebrew on PATH first: antidote calls `zsh` by name, and on Linux/WSL
# that zsh may only exist under linuxbrew.
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Cache brew prefix once to avoid slow subshells (~100-200ms each)
if type brew &>/dev/null; then
  export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
fi

# Emacs key bindings, even though $EDITOR is nvim. zsh picks vi bindings when
# $EDITOR contains "vi", so select emacs before any plugin binds keys --
# switching afterwards would leave those bindings in the vi keymap.
bindkey -e

# Completion paths. These must be on fpath before compinit, which runs inside
# the plugin bundle below (see zsh/compinit.zsh).
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  FPATH=$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH
fi

# Add Docker completions if they exist
docker_completions="$HOME/.docker/completions"
if [[ -d "$docker_completions" ]]; then
  fpath=($docker_completions $fpath)
fi

# Custom spaceship sections; prompt order is set in ~/.spaceshiprc.zsh. These
# are sourced before the spaceship plugin loads, which they rely on: their
# defaults expect $SPACESHIP_PROMPT_DEFAULT_SUFFIX to be unset still, and
# spaceship skips loading a stock section whose function already exists.
source $DOTFILES/zsh/spaceship-prompt/sections/aws_vault.zsh
# source $DOTFILES/zsh/spaceship-prompt/sections/k8s.zsh
source $DOTFILES/zsh/spaceship-prompt/sections/op.zsh
source $DOTFILES/zsh/spaceship-prompt/sections/subshell.zsh
# Overrides the stock dir section (shortens paths inside git worktrees)
source $DOTFILES/zsh/spaceship-prompt/sections/dir.zsh

# Plugins, via antidote (https://antidote.sh). The plugin list is
# zsh/plugins.txt. Cloned rather than installed from Homebrew so the same
# bootstrap works on Linux and WSL.
if [[ ! -d ~/.antidote ]]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote
fi
fpath=(~/.antidote/functions $fpath)
autoload -Uz antidote

# antidote turns the list into a static file of plain source lines, rebuilt only
# when the list changes (see zsh/build-bundle.zsh). The file holds
# machine-specific paths, so it lives in the cache directory rather than the repo.
zsh_plugins=$DOTFILES/zsh/plugins.txt
zsh_bundle=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/plugins.zsh
source $DOTFILES/zsh/build-bundle.zsh
zsh_build_bundle $zsh_plugins $zsh_bundle
if [[ -r $zsh_bundle ]]; then
  source $zsh_bundle
fi
unset zsh_plugins zsh_bundle

bindkey '^ ' autosuggest-accept

# Up/Down (and Ctrl-P/Ctrl-N) search history for entries containing what is
# already typed. Both arrow-key encodings are bound, since terminals send
# either depending on cursor-key mode.
bindkey '^[[A' history-substring-search-up
bindkey '^[OA' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^[OB' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

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

# Put secret stuff in here
if [ -f ~/.localrc ]; then
  . ~/.localrc
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

# Remove dups using zsh built-in
typeset -U path

# uncomment zmodload on line 1 to use profiling
# {
#   echo "=== $(date) ==="
#   zprof
#   echo ""
# } >> ~/zsh_profile.log
