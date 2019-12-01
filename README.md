## Prequisites

* homebrew
* Xcode
* XCode CLI Tools:

    $ xcode-select --install

## Installation

    # Install homebrew package
    brew tap homebrew/cask-fonts
    brew bundle
    $(brew --prefix)/opt/fzf/install

    # Setup dotfile aliases
    make install

    # Setup Vim
    pip3 install --user --upgrade pynvim
    vim
    :PlugUpgrade
    :PlugUpdate
    :UpdateRemotePlugins # neovim

    # ruby
    brew install openssl libyaml libffi
    brew install rbenv ruby-build

    # nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh | bash

    chsh -s $(which zsh)

    # oh-my-zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    # zplug
    curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
    zplug install

    # in zsh
    git clone https://github.com/denysdovhan/spaceship-prompt.git "$ZSH_CUSTOM/themes/spaceship-prompt"
    ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"

## Tmux

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # start tmux session and run prefix-I

### Generate Brewfile

    brew bundle dump

### iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git extras/iTerm2-Color-Schemes
