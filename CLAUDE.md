# Dotfiles Project

Neovim-specific conventions and known issues live in `nvimfiles/CLAUDE.md`.

## Key Conventions

- Reference docs live in `docs/neovim-reference/` and `docs/tmux-reference/` -- keep them in sync when changing configs or plugins

## Terminal & Multiplexer

- **Ghostty** is the terminal emulator; config lives at `extras/ghostty/config` (symlinked to `~/.config/ghostty/config`)
  - Custom themes in `extras/ghostty/themes/`
  - `mouse-shift-capture = false` — hold Shift to bypass tmux mouse capture for native text selection
- **tmux** config is `.tmux.conf` at repo root
  - Plugin manager: **tpack** (`brew install tpack`), a TPM-compatible rewrite. Install it via the Brewfile, not by git-cloning TPM. Plugins are declared with `set -g @plugin` lines (all before `run 'tpack init'`, which stays at the bottom of `.tmux.conf`); tpack clones them into `~/.tmux/plugins/` (not tracked). Install/update via `prefix + I` or the TUI (`prefix + T`).

## Other Dotfiles

- `.zshrc` -- zsh config; plugins are managed by **antidote** (cloned to `~/.antidote`, not Homebrew, so it works on Linux/WSL). The plugin list is `zsh/plugins.txt`, compiled to a static bundle at `~/.cache/zsh/plugins.zsh` that rebuilds when the list changes. `compinit` runs once, from `zsh/compinit.zsh`, at its place in that list (after fpath plugins, before fzf-tab).
- `Brewfile` -- Homebrew packages (includes tree-sitter and tree-sitter-cli for treesitter parser compilation)
- Monicur project (`~/code/monicur/monicur`) has a `.nvim.lua` for dadbod DATABASE_URL integration
