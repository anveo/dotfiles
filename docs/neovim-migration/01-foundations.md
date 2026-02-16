# 01 -- Directory Structure and Core Config

## Target Directory Structure

```
nvimfiles/
  init.lua                      -- entrypoint: requires everything
  lua/
    options.lua                 -- vim.opt settings
    keymaps.lua                 -- all keybindings
    autocmds.lua                -- autocommands
    commands.lua                -- user commands
    config/
      lazy.lua                  -- lazy.nvim bootstrap + setup
    plugins/                    -- one file per plugin (or group)
      colorscheme.lua
      treesitter.lua
      telescope.lua
      neo-tree.lua
      lsp.lua
      completion.lua
      git.lua
      ui.lua
      editing.lua
      flash.lua
      ...
  after/
    ftplugin/
      ruby.lua                  -- 2-space indent, interpolation helper
      go.lua                    -- 4-space hard tabs
      javascript.lua            -- 2-space indent
      markdown.lua              -- wrap, textwidth=80
      make.lua                  -- real tabs
      python.lua                -- 4-space, noexpandtab
```

lazy.nvim's `{ import = "plugins" }` pattern auto-loads every `.lua` file in `lua/plugins/`. Each file returns a plugin spec table. This keeps the config modular -- you can add/remove plugins by adding/removing files.

## `init.lua` Entrypoint

The existing `nvimfiles/init.lua` is close. Expand it to:

```lua
-- Ensure nvimfiles/ is on the runtime path (needed for `nvim -u` usage)
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
vim.opt.rtp:prepend(config_dir)

require("options")
require("keymaps")
require("autocmds")
require("commands")
require("config.lazy")
```

The `rtp:prepend` line is needed when testing with `nvim -u ~/dotfiles/nvimfiles/init.lua` -- without it, Lua's `require()` can't find modules in `nvimfiles/lua/`. Once the symlink is set up (chapter 09), neovim adds the config directory to rtp automatically, but the line is harmless to keep.

Order matters: options and leader key must be set before lazy.nvim loads plugins (some plugins read `mapleader` at load time).

## `lua/options.lua`

Port from `vimfiles/config/settings.vim`. The current `nvimfiles/lua/options.lua` has a good start but is missing several settings.

```lua
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.numberwidth = 3

-- Indentation (4-space default; Ruby overridden in after/ftplugin/ruby.lua)
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true

-- Search
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true          -- MISSING from current nvimfiles draft

-- Display
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.termguicolors = true
vim.opt.list = true
vim.opt.listchars = { tab = "»·", trail = "·" }
vim.opt.colorcolumn = "120"

-- Scrolling
vim.opt.scrolloff = 999           -- cursor stays centered; revert to 3 if disorienting
vim.opt.scrolljump = 5

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Buffers
vim.opt.hidden = true

-- Folding (treesitter-based -- see chapter 07)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Command-line completion
vim.opt.wildmode = "list:longest,full"
vim.opt.wildmenu = true
vim.opt.wildignore:append({
  "*~", "*.scssc", "*.sassc", "*.png", "*.PNG", "*.JPG", "*.jpg",
  "*.GIF", "*.gif", "*.dat", "*.doc", "*.DOC", "*.log", "*.pdf",
  "*.PDF", "*.ppt", "*.docx", "*.pptx", "*.wpd", "*.zip", "*.rtf",
  "*.eps", "*.psd", "*.ttf", "*.otf", "*.eot", "*.svg", "*.woff",
  "*.mp3", "*.mp4", "*.m4a", "*.wav",
  "log/**", "vendor/**", "coverage/**", "tmp/**",
})

-- History and undo
vim.opt.history = 1000
vim.opt.undofile = true

-- Misc
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.mouse = "a"
vim.opt.complete:remove("i")
vim.opt.nrformats = { "bin", "hex", "alpha" }
vim.opt.clipboard = "unnamedplus"
vim.opt.virtualedit = "block"
vim.opt.inccommand = "split"      -- live substitution preview (neovim-only)

-- Temp files
vim.opt.directory = "/tmp/"

-- Encoding
vim.opt.encoding = "utf8"

-- Grep program
vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"
```

### Changes from `vimfiles/config/settings.vim`

| Setting | Old (vimfiles) | New (nvimfiles) | Why |
|---|---|---|---|
| `shiftwidth` | 2 | **4** | Decision: 4-space default |
| `softtabstop` | 2 | **4** | Matches new shiftwidth |
| `scrolloff` | 3 | **999** | Centered cursor; revert to 3 if you hate it |
| `smartcase` | set | set | Already present in vimfiles but **missing from nvimfiles draft** |
| `grepprg` | `ack` | **`rg`** | ripgrep is faster and already installed |
| `ttymouse` | `xterm2` | removed | Neovim handles mouse natively |
| `t_Co` | `256` | removed | `termguicolors` handles this |
| tmux cursor | `t_SI`/`t_EI` | removed | Neovim sets cursor shape natively |
| WSL yank | custom augroup | removed | `clipboard = "unnamedplus"` handles this |

### Reverting `scrolloff=999`

If centered scrolling feels wrong:

```lua
vim.opt.scrolloff = 3    -- original value
-- or
vim.opt.scrolloff = 0    -- vim default, no offset
```

## Symlink Change

In `bin/install.sh`, change line 26 from:

```bash
ln -nfs $HOME/dotfiles/vimfiles $HOME/.config/nvim
```

to:

```bash
ln -nfs $HOME/dotfiles/nvimfiles $HOME/.config/nvim
```

**Don't make this change yet** -- do it in [09-cleanup](09-cleanup.md) after the full config is ready. Until then, you can test `nvimfiles/` by launching neovim with:

```bash
NVIM_APPNAME=nvimfiles nvim
# or
nvim --clean -u ~/dotfiles/nvimfiles/init.lua
```

## Update `lazy.lua`

The current `nvimfiles/lua/config/lazy.lua` has inline plugin specs. Move to the `{ import = "plugins" }` pattern:

```lua
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    { import = "plugins" },   -- auto-load lua/plugins/*.lua
  },
  install = { colorscheme = { "jellybeans", "habamax" } },
  checker = { enabled = false },  -- run :Lazy update manually
})
```

Then move the kanagawa/treesitter specs into separate files under `lua/plugins/`. For example, `lua/plugins/treesitter.lua` would return the treesitter spec table.

## Checklist

- [ ] Update `init.lua` to require options, keymaps, autocmds, commands, lazy
- [ ] Update `lua/options.lua` with all settings above
- [ ] Add `smartcase` (currently missing)
- [ ] Add `softtabstop = 4`
- [ ] Add `wildignore`, `history`, `foldmethod`, `listchars`, etc.
- [ ] Refactor `lua/config/lazy.lua` to use `{ import = "plugins" }` pattern
- [ ] Create `lua/plugins/` directory
- [ ] Move treesitter spec to `lua/plugins/treesitter.lua`
- [ ] Create empty `lua/keymaps.lua`, `lua/autocmds.lua`, `lua/commands.lua` (populated in chapter 02)
- [ ] Test: `nvim --clean -u ~/dotfiles/nvimfiles/init.lua` launches without errors
- [ ] Test: `:checkhealth` passes with no critical errors
