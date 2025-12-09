#!/usr/bin/env bash

set -e

# misc
mkdir -p $HOME/bin
mkdir -p $HOME/local/include # gcc warning
mkdir -p $HOME/tmp
touch $HOME/.gitsecrets

ln -fs $HOME/dotfiles/scripts/consolidate-path $HOME/bin/consolidate-path

ln -nfs $HOME/dotfiles/scripts $HOME/scripts

# vim
ln -nfs $HOME/dotfiles/vimfiles $HOME/.vim
ln -fs $HOME/dotfiles/vimfiles/.vimrc $HOME/.vimrc

ln -nfs $HOME/dotfiles/.spaceshiprc.zsh $HOME/.spaceshiprc.zsh

# neovim
mkdir -p $HOME/.config
mkdir -p $HOME/.config/kitty/themes
ln -nfs $HOME/dotfiles/kitty.conf $HOME/.config/kitty/kitty.conf
ln -nfs $HOME/dotfiles/extras/kitty/themes/brian.conf $HOME/.config/kitty/themes/brian.conf
ln -nfs $HOME/dotfiles/vimfiles $HOME/.config/nvim
mkdir -p $HOME/.config/autokey/data
ln -nfs $HOME/dotfiles/extras/autokey/emacs $HOME/.config/autokey/data/emacs

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

mkdir -p $HOME/.claude/{plans,plugins}
ln -nfs $HOME/dotfiles/extras/claude/commands $HOME/.claude/commands
