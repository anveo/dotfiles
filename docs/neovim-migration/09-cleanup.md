# 09 -- Install Script, Env, Dead Code, Freeze

This is the final chapter. By now your `nvimfiles/` config should be fully functional. This chapter cuts over from `vimfiles/` for real.

## `bin/install.sh`: Switch the Symlink

Change line 26 from:

```bash
ln -nfs $HOME/dotfiles/vimfiles $HOME/.config/nvim
```

to:

```bash
ln -nfs $HOME/dotfiles/nvimfiles $HOME/.config/nvim
```

The full context (lines 21-26):

```bash
# neovim
mkdir -p $HOME/.config
mkdir -p $HOME/.config/kitty/themes
ln -nfs $HOME/dotfiles/kitty.conf $HOME/.config/kitty/kitty.conf
ln -nfs $HOME/dotfiles/extras/kitty/themes/brian.conf $HOME/.config/kitty/themes/brian.conf
ln -nfs $HOME/dotfiles/nvimfiles $HOME/.config/nvim    # <-- changed
```

After making this change, run:

```bash
# Remove old symlink and relink
rm -f ~/.config/nvim
~/dotfiles/bin/install.sh
```

## `bash/env`: Update EDITOR

Change the editor settings:

**Line 2**, change:
```bash
export EDITOR="vim"
```
to:
```bash
export EDITOR="nvim"
```

**Line 21** (macOS override), change:
```bash
export EDITOR="mvim -v"
```
to:
```bash
export EDITOR="nvim"
```

The full file context:

```bash
# Make nvim the default editor
export EDITOR="nvim"

# ...

if [ `uname` = 'Darwin' ]; then
  # No longer need MacVim
  export EDITOR="nvim"
fi
```

You could also simplify by removing the macOS override entirely since nvim works the same on all platforms.

## `bash/aliases`: Already Done

Lines 162-165 already alias `vi` and `vim` to nvim:

```bash
if [ -x $(type nvim &>/dev/null) ]; then
  alias vi=$(which nvim)
  alias vim=$(which nvim)
fi
```

No changes needed here.

## Python Host

Your `vimfiles/config/plugins.vim` line 282 sets:

```vim
let g:python3_host_prog = expand('$HOME/.pyenv/versions/neovim3/bin/python')
```

**Do you still need this?** Check:
1. Any plugins that require Python? (`:checkhealth provider` will tell you)
2. If no Python-dependent plugins remain, skip it entirely
3. If needed, add to `lua/options.lua`:

```lua
vim.g.python3_host_prog = vim.fn.expand("$HOME/.pyenv/versions/neovim3/bin/python")
```

Most likely you can skip it. The Python-dependent plugins (deoplete, semshi) are not in the new config.

## Dead Code in vimfiles

Things to note as you freeze the old config:

| Item | Location | Status |
|---|---|---|
| jedi-vim | `~/.vim/plugged/jedi-vim/` exists | Not in `.vimrc` -- leftover from `:PlugInstall` |
| deoplete settings | `plugins.vim` lines 172-175 | Referenced but deoplete is commented out |
| neosnippet settings | `plugins.vim` lines 193-216 | Entirely commented out |
| neomake settings | `plugins.vim` lines 177-191 | Entirely commented out |
| semshi settings | `.vimrc` line 73 | Commented out |
| `ZoomWin` autoload | `autoload/ZoomWin.vim` | Plugin is in both autoload/ and plugged/ |
| processing.vim ftplugin | `ftplugin/processing.vim` | Processing no longer used |
| coffee.vim ftplugin | `ftplugin/coffee.vim` | CoffeeScript no longer used |
| php.vim ftplugin | `ftplugin/php.vim` | Contents were all commented out |

## Freeze vimfiles

Add a note to `vimfiles/` indicating it's archived:

1. The old config still works for vanilla Vim (the `.vimrc` and `~/.vim` symlink remain)
2. No further changes should go into `vimfiles/`
3. `nvimfiles/` is the active neovim config

Consider adding a one-line note at the top of `vimfiles/.vimrc`:

```vim
" NOTE: This config is frozen. Active neovim config is in nvimfiles/
```

## Final Verification

After making all changes, verify:

```bash
# 1. Symlink points to nvimfiles
ls -la ~/.config/nvim
# Should show: ~/.config/nvim -> /Users/bracer/dotfiles/nvimfiles

# 2. EDITOR is nvim
echo $EDITOR
# Should show: nvim

# 3. Neovim launches cleanly
nvim --headless "+checkhealth" "+qa"

# 4. Aliases work
which vi   # should show nvim
which vim  # should show nvim
```

## Summary of All Changes to Non-nvimfiles

| File | Change |
|------|--------|
| `bin/install.sh` line 26 | `vimfiles` -> `nvimfiles` |
| `bash/env` line 2 | `EDITOR="vim"` -> `EDITOR="nvim"` |
| `bash/env` line 21 | `EDITOR="mvim -v"` -> `EDITOR="nvim"` |
| `vimfiles/.vimrc` line 1 | Add frozen notice |
| `bash/aliases` | No change needed |

## Checklist

- [ ] Update `bin/install.sh` symlink to nvimfiles
- [ ] Update `bash/env` EDITOR to nvim (both lines)
- [ ] Run `install.sh` to apply symlink change
- [ ] Verify `~/.config/nvim` points to nvimfiles
- [ ] Verify `$EDITOR` is nvim
- [ ] Run `:checkhealth` -- no critical errors
- [ ] Verify vanilla Vim still works (opens with `vimfiles/` config via `~/.vim` symlink)
- [ ] Add frozen notice to `vimfiles/.vimrc`
- [ ] Commit everything
- [ ] Open a real project and work for a day -- note any missing bindings or behaviors
- [ ] Celebrate
