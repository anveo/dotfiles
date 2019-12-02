if [[ ! -d ~/.zplug ]];then
  git clone https://github.com/b4b4r07/zplug ~/.zplug
fi

source ~/.zplug/init.zsh

if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
fi

# oh-my-zsh
# zplug "robbyrussell/oh-my-zsh", use:"lib/*.zsh"
zplug "lib/*", from:oh-my-zsh

# spaceship-prompt
zplug "denysdovhan/spaceship-prompt", use:spaceship.zsh, from:github, as:theme

source $HOME/dotfiles/zsh/spaceship-prompt/sections/aws_vault.zsh
source $HOME/dotfiles/zsh/spaceship-prompt/sections/op.zsh
source $HOME/dotfiles/zsh/spaceship-prompt/sections/subshell.zsh

# Path to your oh-my-zsh installation.
# export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="spaceship"

if zplug check "denysdovhan/spaceship-prompt"; then
  SPACESHIP_TIME_SHOW=true
  SPACESHIP_TIME_COLOR="250"
  SPACESHIP_CHAR_SYMBOL="∴"
  SPACESHIP_CHAR_SUFFIX=" "
  # SPACESHIP_PROMPT_DEFAULT_PREFIX=""
  SPACESHIP_PROMPT_PREFIXES_SHOW="false"
  SPACESHIP_DIR_PREFIX=""
  SPACESHIP_DIR_TRUNC="8"
  SPACESHIP_DIR_LOCK_SYMBOL="${SPACESHIP_DIR_LOCK_SYMBOL=" "}"
  SPACESHIP_GIT_PREFIX=""
  # SPACESHIP_KUBECONTEXT_SYMBOL=" "
  SPACESHIP_NODE_SYMBOL=" "
  SPACESHIP_PACKAGE_SHOW="false"
  SPACESHIP_RUBY_SYMBOL="  "
  SPACESHIP_EXIT_CODE_SHOW="true"

  SPACESHIP_PROMPT_ORDER=(
    subshell
    # time          # Time stamps section
    # user          # Username section
    dir           # Current directory section
    # host          # Hostname section
    git           # Git section (git_branch + git_status)
    # hg            # Mercurial section (hg_branch  + hg_status)
    # package       # Package version
    node          # Node.js section
    ruby          # Ruby section
    elixir        # Elixir section
    # xcode         # Xcode section
    # swift         # Swift section
    golang        # Go section
    # php           # PHP section
    rust          # Rust section
    # haskell       # Haskell Stack section
    # julia         # Julia section
    docker        # Docker section
    aws           # Amazon Web Services section
    venv          # virtualenv section
    conda         # conda virtualenv section
    pyenv         # Pyenv section
    # dotnet        # .NET section
    # ember         # Ember.js section
    kubecontext   # Kubectl context section
    terraform     # Terraform workspace section
    # exec_time     # Execution time
    line_sep      # Line break
    battery       # Battery level and status
    vi_mode       # Vi-mode indicator
    jobs          # Background jobs indicator
    # exit_code     # Exit code section
    char          # Prompt character
  )

  SPACESHIP_RPROMPT_ORDER=(
    awsvault
    op
    exec_time     # Execution time
    exit_code     # Exit code section
    time          # Time stamps section
  )
fi

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in ~/.oh-my-zsh/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"
CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS=true

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyy/mm/dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=$HOME/dotfiles/zsh/oh-my-zsh

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

plugins=(
  brew
  git
  nvm
  pyenv
  rbenv
)

# source $ZSH/oh-my-zsh.sh

# Make sure to use double quotes

zplug "chrissicool/zsh-256color"
zplug "mafredri/zsh-async", from:github, use:async.zsh
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-history-substring-search", defer:3

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

source $HOME/dotfiles/bash/aliases
source $HOME/dotfiles/bash/functions
source $HOME/dotfiles/bash/env
source $HOME/dotfiles/bash/paths

# source $HOME/dotfiles/shell/autojump.sh
source $HOME/dotfiles/shell/direnv.sh
source $HOME/dotfiles/shell/fzf.sh
source $HOME/dotfiles/shell/nvm.sh
source $HOME/dotfiles/shell/rbenv.sh
source $HOME/dotfiles/shell/z.sh

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

zplug load # --verbose
