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

Plugins are managed by [tpack](https://github.com/tmuxpack/tpack), a
TPM-compatible plugin manager installed via Homebrew (included in the Brewfile):

    brew install tpack

Then start a tmux session and press `prefix + I` to install the plugins
declared in `.tmux.conf`. tpack clones them into `~/.tmux/plugins/` (not
tracked in this repo). Use `prefix + T` for the interactive TUI.

## Claude Code MCP cohorts

`scripts/mcp-cohort` gives groups of projects ("cohorts") their own set of MCP
servers, local (stdio) or remote (HTTP), by adding them to each project at
Claude Code's local scope. It works in both the terminal and the desktop app,
and writes nothing into the repos. Typical uses: a different Linear or Notion
account per cohort, or internal servers only work projects should see. Full
guide: [Local MCP Setup](https://app.notion.com/p/40e8f83c912980bf9ec7ec9e8c42b146).

Cohort files live in `~/.config/mcp-cohort/<cohort>.json` (override with
`MCP_COHORT_DIR`). They are **not** in this repo: they grow to hold private and
local server addresses. Example `~/.config/mcp-cohort/personal.json`:

```json
{
  "mcpServers": {
    "linear-personal": {
      "type": "http",
      "url": "https://mcp.linear.app/mcp?account=personal"
    },
    "notion-personal": {
      "type": "http",
      "url": "https://mcp.notion.com/mcp?account=personal"
    },
    "db-personal": {
      "type": "stdio",
      "command": "uvx",
      "args": ["postgres-mcp", "--access-mode=restricted"],
      "env": { "DATABASE_URI": "postgresql://user:pass@localhost:5432/personal" }
    }
  }
}
```

The first two are remote (`http`) servers; `db-personal` is a local (`stdio`)
server that Claude Code starts as a subprocess, with the cohort's own database in
`env`. Use absolute paths in `args`, since `~` is not expanded. Only servers that
differ per cohort belong here. Servers that are the same everywhere, such as
context7 or filesystem, belong at user scope (`claude mcp add -s user …`).

A cohort file can hold any server entry `claude mcp add-json` accepts. For OAuth
servers, each distinct URL gets its own sign-in, so an `?account=` label keeps
two accounts of the same service apart. Values are copied as written into
`~/.claude.json`; `${VAR}` placeholders are expanded only at run time, and the
desktop app does not see your shell environment. Then apply it and sign in once
through `/mcp`:

    mcp-cohort personal ~/code/personal/*(/)

`*(/)` is one level deep; for repos at any depth use
`~/code/personal/**/.git(/N:h)`, which matches every repo root (worktrees are
skipped and inherit from their repo).

After editing a cohort file, update every project that uses it in one go, from
any directory (it finds them in `~/.claude.json`):

    mcp-cohort --sync personal

`--sync` edits `~/.claude.json` directly (with a backup at
`~/.claude.json.mcp-cohort.bak`) and asks first if Claude Code is running;
restart running sessions afterwards.

A user-scope server can be the default everywhere with cohorts overriding it,
as long as the cohort's server has exactly the same name (e.g. `linear` at user
scope, and `"linear": {"url": "https://mcp.linear.app/mcp?account=work"}` in
`work.json`): local scope replaces a same-named user-scope server outright. The
catch is that any repo not yet in a cohort silently gets the default, so keep
account-specific defaults off machines that mix work and personal.

Never `claude mcp remove` a cohort server: it signs that URL out in every
project on the machine.

## Generate Brewfile

    brew bundle dump

## iTerm Themes

    git clone git@github.com:mbadolato/iTerm2-Color-Schemes.git extras/iTerm2-Color-Schemes
    git clone https://github.com/martinlindhe/base16-iterm2.git extras/base16-iterm2

## WSL

    command -v zsh | sudo tee -a /etc/shells
    chsh -s $(which zsh)

## Windows

Double-click `install-windows.cmd` (or run it from cmd/PowerShell) to copy the
scripts in `extras/windows/bin` into `C:\bin`, which must already be on the
Windows PATH. These are plain copies, not symlinks, so re-run it after editing a
script. Each `<name>.ps1` gets a `<name>.cmd` shim so it runs by name from cmd
and the Run dialog. See `extras/windows/README.md` for the one-off setup and
debloat scripts.

From WSL:

    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(wslpath -w extras/windows/install.ps1)"
