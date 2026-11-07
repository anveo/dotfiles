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
- `bin/doctor` -- machine health check (`make doctor`): dangling symlinks, tmux/ghostty/git config, missing alias targets, the rtk hook and RTK.md, Claude hook commands in `~/.claude/settings.json` that point at missing files (`bin/doctor-claude-hooks.sh`), Brewfile. FAIL exits non-zero, WARN does not. Add a check here when an install step can silently break.
- `make check` -- repo checks: `test/syntax_check.sh` parses every tracked shell file (both bash and zsh for `bash/{aliases,functions,env,paths}` and `shell/*.sh`), then the behaviour tests
- Monicur project (`~/code/monicur/monicur`) has a `.nvim.lua` for dadbod DATABASE_URL integration

## Review Guidelines

Reviews are requested by hand with an `@claude` mention on the PR (`.github/workflows/claude.yml`); nothing reviews on push. The `Check` workflow runs `make check` on Ubuntu and macOS -- read its result rather than assuming.

- Files sourced by both `.zshrc` and `.bashrc` (`bash/{aliases,functions,env,paths}`, `shell/*.sh`) must parse and behave in both bash and zsh.
- macOS-only commands (`pmset`, `defaults`, `osascript`, `/Applications/...`) belong inside a Darwin guard.
- A check that cannot run must say so (skip or warn), never report ok. Empty output is not success.
- Checks and tests must not change the machine: no installs, clones, or writes outside a temp dir, and never touch the user's running tmux server.
- Install steps must be idempotent: `make install` is re-run on machines that already have the links.
- Flag behaviour changes the PR description does not mention.
