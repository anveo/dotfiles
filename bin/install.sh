#!/usr/bin/env bash

set -e

# misc
mkdir -p $HOME/bin
mkdir -p $HOME/local/include # gcc warning
mkdir -p $HOME/tmp

# Files that hold tokens or credentials. Create them if missing so a new machine's
# first write is already private, and enforce 600 on every run -- ~/.localrc is
# sourced into every shell's environment, so a world-readable copy leaks whatever
# it exports.
private_files=(
  .gitsecrets
  .localrc
)

for file in "${private_files[@]}"
do
  touch "$HOME/${file}"
  chmod 600 "$HOME/${file}"
done

ln -fs $HOME/dotfiles/scripts/consolidate-path $HOME/bin/consolidate-path

ln -nfs $HOME/dotfiles/scripts $HOME/scripts

# vim
ln -nfs $HOME/dotfiles/vimfiles $HOME/.vim
ln -fs $HOME/dotfiles/vimfiles/.vimrc $HOME/.vimrc

ln -nfs $HOME/dotfiles/.spaceshiprc.zsh $HOME/.spaceshiprc.zsh

# neovim
mkdir -p $HOME/.config
mkdir -p $HOME/.config/kitty/themes
ln -nfs $HOME/dotfiles/extras/kitty/kitty.conf $HOME/.config/kitty/kitty.conf
ln -nfs $HOME/dotfiles/extras/kitty/themes/brian.conf $HOME/.config/kitty/themes/brian.conf
ln -nfs $HOME/dotfiles/nvimfiles $HOME/.config/nvim
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

echo "ln -nfs $HOME/dotfiles/.gitignore.global $HOME/.gitignore"
ln -nfs $HOME/dotfiles/.gitignore.global $HOME/.gitignore

if [ `uname` = 'Darwin' ]; then
  echo "Setting up macOS-specific configs..."

  echo "Setting up espanso configs..."
  ESPANSO_DIR="$HOME/Library/Application Support/espanso"
  mkdir -p "$ESPANSO_DIR/config" "$ESPANSO_DIR/match"
  echo "ln -fs $HOME/dotfiles/extras/espanso/config/default.yml $ESPANSO_DIR/config/default.yml"
  ln -fs "$HOME/dotfiles/extras/espanso/config/default.yml" "$ESPANSO_DIR/config/default.yml"
  echo "ln -fs $HOME/dotfiles/extras/espanso/match/base.yml $ESPANSO_DIR/match/base.yml"
  ln -fs "$HOME/dotfiles/extras/espanso/match/base.yml" "$ESPANSO_DIR/match/base.yml"

  mkdir -p $HOME/.config/karabiner
  echo "ln -nfs $HOME/dotfiles/extras/karabiner.json $HOME/.config/karabiner/karabiner.json"
  ln -nfs $HOME/dotfiles/extras/karabiner.json $HOME/.config/karabiner/karabiner.json
  echo "ln -nfs $HOME/dotfiles/extras/hammerspoon $HOME/.hammerspoon"
  ln -nfs $HOME/dotfiles/extras/hammerspoon $HOME/.hammerspoon

  mkdir -p $HOME/.config/ghostty
  # Remove macOS-specific default config to use XDG location instead
  rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  echo "ln -nfs $HOME/dotfiles/extras/ghostty/config $HOME/.config/ghostty/config"
  ln -nfs $HOME/dotfiles/extras/ghostty/config $HOME/.config/ghostty/config
  echo "ln -nfs $HOME/dotfiles/extras/ghostty/themes $HOME/.config/ghostty/themes"
  ln -nfs $HOME/dotfiles/extras/ghostty/themes $HOME/.config/ghostty/themes

  LAZYGIT_LIB_DIR="$HOME/Library/Application Support/lazygit"
  mkdir -p "$LAZYGIT_LIB_DIR"
  echo "ln -fs $HOME/dotfiles/extras/lazygit/config.yml $LAZYGIT_LIB_DIR/config.yml"
  ln -fs "$HOME/dotfiles/extras/lazygit/config.yml" "$LAZYGIT_LIB_DIR/config.yml"

  echo "Running macOS defaults script..."
  $HOME/dotfiles/extras/macos_defaults.sh
elif [ `uname` = 'Linux' ]; then
  echo "Setting up Linux-specific configs..."

  # echo "Setting up espanso configs..."
  # ESPANSO_DIR="$HOME/.config/espanso"
  # mkdir -p "$ESPANSO_DIR/config" "$ESPANSO_DIR/match"
  # ln -fs "$HOME/dotfiles/extras/espanso/config/default.yml" "$ESPANSO_DIR/config/default.yml"
  # ln -fs "$HOME/dotfiles/extras/espanso/match/base.yml" "$ESPANSO_DIR/match/base.yml"
fi

echo "Setting up VisiData configs..."
mkdir -p $HOME/.visidata
echo "ln -nfs $HOME/dotfiles/extras/visidata/config.py $HOME/.visidata/config.py"
ln -nfs $HOME/dotfiles/extras/visidata/config.py $HOME/.visidata/config.py

echo "Setting up lazygit configs..."
mkdir -p "$HOME/.config/lazygit"
echo "ln -fs $HOME/dotfiles/extras/lazygit/config.yml $HOME/.config/lazygit/config.yml"
ln -fs "$HOME/dotfiles/extras/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"

echo "Setting up tig configs..."
echo "ln -nfs $HOME/dotfiles/extras/tig/config $HOME/.tigrc"
ln -nfs $HOME/dotfiles/extras/tig/config $HOME/.tigrc

echo "Setting up glow configs..."
mkdir -p "$HOME/.config/glow"
echo "ln -fs $HOME/dotfiles/extras/glow/glow.yml $HOME/.config/glow/glow.yml"
ln -fs "$HOME/dotfiles/extras/glow/glow.yml" "$HOME/.config/glow/glow.yml"

$HOME/dotfiles/bin/install-ai.sh
