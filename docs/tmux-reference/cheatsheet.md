# tmux Cheatsheet

Quick reference for the tmux config. Prefix is `C-Space`.

---

## Sessions, Windows, Panes

### Windows (tabs)

| Key | Action |
|-----|--------|
| `prefix c` / `prefix C-c` | New window |
| `prefix e` | Previous window |
| `prefix f` | Next window |
| `prefix C-h` | Previous window (repeatable) |
| `prefix C-l` | Next window (repeatable) |
| `prefix 1-9` | Jump to window by number |
| Click status bar tab | Switch to that window (mouse) |

### Panes

| Key | Action |
|-----|--------|
| `prefix \|` / `prefix h` | Split vertically (top/bottom) |
| `prefix -` / `prefix v` | Split horizontally (left/right) |
| `C-h/j/k/l` | Navigate panes (vim-tmux-navigator -- works across nvim splits) |
| `prefix H/J/K/L` | Resize pane by 5 cells (repeatable) |
| `prefix Up` / `prefix Down` | Toggle zoom on current pane |
| Click a pane | Select it (mouse) |
| Drag pane border | Resize (mouse) |

### Sessions

| Key | Action |
|-----|--------|
| `prefix d` | Detach from session |
| `prefix s` | List sessions (built-in picker) |
| `prefix $` | Rename session |
| `prefix (` / `)` | Previous/next session |

---

## Copy Mode (vi)

Enter with `prefix Space` or `prefix C-Space`.

| Key | Mode | Action |
|-----|------|--------|
| `v` | copy | Begin selection |
| `V` | copy | Toggle rectangle selection |
| `y` | copy | Yank selection (copies to system clipboard via pbcopy) |
| `Y` | copy | Yank to end of line |
| `Enter` | copy | Yank selection and exit copy mode |
| `q` / `Escape` | copy | Exit copy mode |
| `prefix p` | normal | Paste buffer |
| `prefix C-c` | normal | Save buffer to system clipboard |
| `prefix C-v` | normal | Paste from system clipboard |
| Mouse drag | copy | Select text and copy to clipboard on release |
| `Shift` + mouse drag | -- | Ghostty native selection (bypasses tmux) |

### Searching in copy mode

| Key | Action |
|-----|--------|
| `/` | Search forward (regex) |
| `?` | Search backward (regex) |
| `n` / `N` | Next/previous match |

---

## General

| Key | Action |
|-----|--------|
| `prefix r` | Reload tmux config |
| `prefix C-l` | Send `C-l` to pane (clear screen) |
| `C-\` | Send prefix to nested session (e.g. overmind) |
| Scroll wheel | Scroll pane / enter copy mode (mouse) |

---

## Installed Plugins

Managed by [TPM](https://github.com/tmux-plugins/tpm). Install with `prefix I`, update with `prefix U`.

| Plugin | What it does | Status |
|--------|-------------|--------|
| [tmux-yank](https://github.com/tmux-plugins/tmux-yank) | System clipboard integration for copy mode. Adds `y` to yank to clipboard, `Y` to put selection on command line. Supplements manual pbcopy bindings. | Active |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-saves tmux environment every 15 min. Auto-restores on tmux start. **Depends on tmux-resurrect.** | Active, but see note below |

### vim-tmux-navigator (built into tmux.conf)

Not a TPM plugin -- the logic is inlined in `.tmux.conf`. Enables seamless `C-h/j/k/l` navigation between tmux panes and neovim splits. Also handles fzf panes correctly (C-j/C-k pass through to fzf).

### Note: tmux-resurrect

The resurrect strategy is configured (`@resurrect-strategy-nvim 'session'`) but the plugin itself is **commented out** in the TPM list. tmux-continuum depends on resurrect to do anything, so continuum is currently a no-op.

Options:
1. **Re-enable resurrect** -- uncomment it in the TPM plugins list, run `prefix I` to install. Save with `prefix C-s`, restore with `prefix C-r`.
2. **Remove continuum** -- if you don't want session persistence, drop both.

---

## Plugins Worth Considering

Workflow-level plugins that pair well with this config. Ordered by likely impact.

### extrakto -- fuzzy text grabber

[laktak/extrakto](https://github.com/laktak/extrakto)

Press `prefix Tab` to fzf-search all text visible in the current pane (or all panes). Finds file paths, URLs, git SHAs, words -- anything. Select to copy or insert at the cursor. Extremely useful for grabbing paths from stack traces and test output.

Requires: fzf (already installed), tmux 3.2+ (for popups).

```
set -g @tpm_plugins '... laktak/extrakto'
```

### tmux-thumbs -- hint-based text yanking

[fcsonline/tmux-thumbs](https://github.com/fcsonline/tmux-thumbs)

Highlights "interesting" text on screen (paths, SHAs, IPs, UUIDs) with single-letter hints, Vimium-style. Press a letter to yank that text. Faster than extrakto when you can see what you want. Written in Rust.

Requires: Rust toolchain (compiles on install). Default keybinding (`prefix Space`) conflicts with copy mode -- remap it:

```
set -g @thumbs-key F
```

### tmux-open -- open files and URLs from copy mode

[tmux-plugins/tmux-open](https://github.com/tmux-plugins/tmux-open)

In copy mode, highlight text and press `o` to open with system default (browser for URLs, Finder for paths). Press `C-o` to open in `$EDITOR`. Press `S` to web-search the selection.

```
set -g @tpm_plugins '... tmux-plugins/tmux-open'
```

### tmux-sessionx -- fzf session manager

[omerxx/tmux-sessionx](https://github.com/omerxx/tmux-sessionx)

Popup fzf picker for sessions. Switch, create (type a new name), rename, or delete sessions. Optional zoxide integration for auto-cd. Good if you run separate sessions per project (Rails, TypeScript, dotfiles, etc.).

Requires: fzf, tmux 3.2+.

```
set -g @tpm_plugins '... omerxx/tmux-sessionx'
```

### tmux-fzf -- general-purpose tmux manager

[sainnhe/tmux-fzf](https://github.com/sainnhe/tmux-fzf)

`prefix F` opens fzf to manage everything: sessions, windows, panes, keybindings. Supports multi-select and previews. Broader than sessionx but less focused. Pick one or the other.

---

## Superseded Plugins (skip these)

These are in the commented-out section of `.tmux.conf`. All are outdated.

| Plugin | Why skip it |
|--------|-------------|
| tmux-copycat | Superseded by tmux's built-in regex search in copy mode (tmux 3.1+) |
| tmux-fpp | Facebook PathPicker -- rarely maintained. extrakto/thumbs are better. |
| tmux-urlview | Requires external `urlview` tool. extrakto or tmux-fzf-url are better. |
| tmux-scroll-copy-mode | Unnecessary since tmux 2.1 -- scroll-to-copy-mode is built in. |
| tmux-sensible | Redundant -- every option it sets is already in this config. |
| tmux-sidebar | Directory tree in tmux. neo-tree in neovim is better. |
| tmux-sessionist | Session keybindings. Superseded by tmux-sessionx or tmux-fzf. |
| tmux-fingers | Original hint-mode yanker (Bash). Superseded by tmux-thumbs (Rust). |
