## Prequisites

* homebrew
* Xcode
* XCode CLI Tools:

    $ xcode-select --install

## Installation

```shell
# Install homebrew package
brew tap homebrew/cask-fonts
brew bundle

# Setup dotfile aliases
make install

# Setup python
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
exec $SHELL
pyenv install 2.7.18
pyenv install 3.8.5
pyenv global 3.8.5
pip3 install --upgrade pip

# (optional) Homebrew setup doctor
# set these env vars if `pyenv doctor` errors
# `brew info openssl` for more info
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
pyenv doctor

# Setup Vim
pyenv virtualenv 2.7.18 neovim2
pyenv activate neovim2
pip install --upgrade pip
pip install --upgrade flake8 neovim pynvim

pyenv virtualenv 3.8.5 neovim3
pyenv activate neovim3
pip install --upgrade pip
pip install --upgrade flake8 neovim pynvim
ln -nfs `pyenv which flake8` ~/bin/flake8

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
```

## Tmux

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # start tmux session and run prefix-I

## Generate Brewfile

    brew bundle dump

## iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git extras/iTerm2-Color-Schemes
    git clone https://github.com/martinlindhe/base16-iterm2.git extras/base16-iterm2
