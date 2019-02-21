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

    $ asdf plugin-add ruby
    $ asdf plugin-add nodejs
    $ bash /usr/local/Cellar/asdf/0.5.1/plugins/nodejs/bin/import-release-team-keyring

## Tmux

    brew install reattach-to-user-namespace
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

### Generate Brewfile

    $ brew bundle dump

### iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git
