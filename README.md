## Prequisites

* homebrew
* Xcode
* XCode CLI Tools:

    $ xcode-select --install

## Installation

    # Install homebrew package
    $ brew bundle

    $ brew tap thoughtbot/formulae

    # Setup dotfile aliases
    $ rake install

    # Setup Vim
    $ ./scripts/install_vim_files.sh

    # Add cask path for Alfred
    $ homebrew cask alfred link

    # for js linting
    $ npm install -g jshint

## Tmux

    brew install reattach-to-user-namespace
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

### iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git
