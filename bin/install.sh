#!/usr/bin/env bash

set -e

mkdir -p $HOME/tmp 

# ln -nfs $HOME/dotfiles/scripts $HOME/scripts
# ln -nfs $HOME/dotfiles/vimfiles $HOME/.vim
# ln -fs $HOME/dotfiles/vimfiles/.vimrc $HOME/.vimrc

# mkdir -p $HOME/.config
# ln -nfs $HOME/dotfiles/vimfiles $HOME/.config/nvim

# ln -nfs $HOME/dotfiles/.zshrc $HOME/.zshrc 

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
  .sqlrc
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
