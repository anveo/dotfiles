## Prerequisites

* Homebrew
* Xcode
* Xcode CLI Tools:

      xcode-select --install

## Installation

```shell
# Install homebrew packages
brew bundle

# Symlink dotfiles
make install

# Setup python (uv replaces pyenv)
curl -LsSf https://astral.sh/uv/install.sh | sh

# fnm (Node version manager)
fnm install --lts

# zplug
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
zplug install

# Set default shell
chsh -s $(which zsh)

# Claude Code (optional)
curl -fsSL https://claude.ai/install.sh | bash
```

## Neovim

Plugins auto-install on first launch via lazy.nvim. Treesitter parsers
also install automatically.

If treesitter parsers fail to compile, check `:checkhealth nvim-treesitter`
and ensure `tree-sitter` is installed (`brew install tree-sitter`).

After upgrading neovim, recompile parsers:

    :TSUpdate

See `docs/neovim-reference/` for keybinding cheatsheet and plugin inventory.

## Tmux

    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    # start tmux session and run prefix-I

## Generate Brewfile

    brew bundle dump

## iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git extras/iTerm2-Color-Schemes
    git clone https://github.com/martinlindhe/base16-iterm2.git extras/base16-iterm2

## WSL

    command -v zsh | sudo tee -a /etc/shells
    chsh -s $(which zsh)
