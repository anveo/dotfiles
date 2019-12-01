#!/usr/bin/env bash

set -e

# misc
mkdir -p $HOME/tmp

ln -nfs $HOME/dotfiles/scripts $HOME/scripts

# vim
ln -nfs $HOME/dotfiles/vimfiles $HOME/.vim
ln -fs $HOME/dotfiles/vimfiles/.vimrc $HOME/.vimrc

# neovim
mkdir -p $HOME/.config
ln -nfs $HOME/dotfiles/vimfiles $HOME/.config/nvim

# zsh
ln -nfs $HOME/dotfiles/.zshrc $HOME/.zshrc 

symlinks=(
  .ackrc
  .agignore
  .bashrc
  .curlrc
  .digrc
  .gemrc
  .gitattributes
  .gitconfig
  # .gitignore
  .gvimrc
  .irbrc
  .psqlrc
  .pspgconf
  .screenrc
  .tmux.conf
  .Xdefaults
)

for file in "${symlinks[@]}"
do
  echo "ln -nfs $HOME/dotfiles/${file} $HOME/${file}"
  ln -nfs $HOME/dotfiles/${file} $HOME/${file}
done

ln -nfs $HOME/dotfiles/.gitignore.global $HOME/.gitignore

if [ `uname` = 'Darwin' ]; then
  mkdir -p $HOME/.config/karabiner
  ln -nfs $HOME/dotfiles/extras/karabiner.json $HOME/.config/karabiner/karabiner.json
  ln -nfs $HOME/dotfiles/extras/hammerspoon $HOME/.hammerspoon

  $HOME/dotfiles/extras/macos_defaults.sh
fi
