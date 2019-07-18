## Prequisites

* homebrew
* Xcode
* XCode CLI Tools:

    $ xcode-select --install

## Installation

    # Install homebrew package
    $ brew tap homebrew/cask-fonts
    $ brew bundle
    $ $(brew --prefix)/opt/fzf/install

    # Setup dotfile aliases
    $ rake install

    # Setup Vim
    $ pip3 install --user --upgrade pynvim
    $ vim
    :PlugUpgrade
    :PlugUpdate
    :UpdateRemotePlugins # neovim

    $ brew install openssl libyaml libffi
    $ brew install rbenv ruby-build
    $ brew install nvm

## Tmux

    brew install reattach-to-user-namespace
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

### Generate Brewfile

    $ brew bundle dump

### iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git
