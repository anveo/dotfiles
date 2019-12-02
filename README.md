## Prequisites

* homebrew
* Xcode
* XCode CLI Tools:

    $ xcode-select --install

## Installation

    # Install homebrew package
    brew tap homebrew/cask-fonts
    brew bundle

    # Setup dotfile aliases
    make install

    # Setup Vim
    pip3 install --user --upgrade pynvim
    vim
    :PlugUpgrade
    :PlugUpdate
    :UpdateRemotePlugins # neovim

    # nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh | bash

    # set default shell
    chsh -s $(which zsh)

    # zplug
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
    zplug install

## Tmux

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # start tmux session and run prefix-I

## Generate Brewfile

    brew bundle dump

## iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git extras/iTerm2-Color-Schemes
