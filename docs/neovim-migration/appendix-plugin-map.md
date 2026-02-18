# Appendix: Plugin Migration Map

Complete mapping of every plugin in `vimfiles/.vimrc` to its disposition in the new `nvimfiles/` config.

## Legend

| Action | Meaning |
|--------|---------|
| **Keep** | Same plugin, works in neovim as-is |
| **Replace** | Swap for a Lua-native alternative |
| **Remove** | Drop entirely (treesitter/LSP/neovim handles it, or no longer needed) |
| **New** | No old equivalent -- new capability |

---

## UI & Appearance

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `vim-airline` + `vim-airline-themes` | Replace | `lualine.nvim` | Lua-native, faster, LSP/gitsigns integration |
| `vim-devicons` | Replace | `nvim-web-devicons` | Required dependency for neo-tree, telescope, lualine |
| `vim-css-color` | Replace | `nvim-colorizer.lua` | Faster, uses neovim virtual text |
| `vim-vividchalk` | Remove | -- | Unused colorscheme |
| `base16-vim` | Remove | -- | Unused colorscheme |
| `jellybeans+` (colorscheme file) | Replace | `wtfox/jellybeans.nvim` | Treesitter-aware port of jellybeans |
| -- | New | `which-key.nvim` | Keybinding discovery popup |
| -- | New | `indent-blankline.nvim` | Visual indent guides |
| -- | New | `dressing.nvim` | Better UI for code actions, rename, etc. |
| -- | New | `todo-comments.nvim` | Highlight/search TODO, FIXME, HACK |

## Navigation & Fuzzy Finding

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `ctrlp.vim` | Remove | `telescope.nvim` | Telescope replaces all fuzzy finders |
| `fzf` + `fzf.vim` | Remove | `telescope.nvim` | telescope-fzf-native for speed |
| `ack.vim` | Remove | `telescope.nvim` | `live_grep` replaces `:Ack` |
| `bufexplorer` | Remove | `telescope.nvim` | `buffers` picker replaces `:BufExplorer` |
| `nerdtree` | Replace | `neo-tree.nvim` | Lua-native, floating windows, git status |
| `vim-easymotion` | Replace | `flash.nvim` | Treesitter-aware, doesn't override `/` |
| `ZoomWin` | Remove | -- | Use `<C-w>o` or a simple toggle function |
| -- | New | `telescope-fzf-native.nvim` | C-compiled fzf algorithm for telescope |
| -- | New | `harpoon` (v2) | Quick-access file bookmarks |

## Git

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `vim-fugitive` | Keep | -- | Best-in-class git integration |
| `vim-rhubarb` | Keep | -- | GitHub `:GBrowse` support |
| `vim-gitgutter` | Replace | `gitsigns.nvim` | Async, inline blame, hunk staging |
| `vim-git` | Remove | -- | Treesitter handles git file syntax |
| -- | New | `diffview.nvim` | Side-by-side diff viewer |

## Editing & Text Manipulation

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `vim-surround` | Keep | -- | Or replace with `mini.surround` later |
| `vim-repeat` | Keep | -- | Makes `.` work with plugin mappings |
| `vim-commentary` | Remove | -- | Neovim 0.10+ has built-in `gc` commenting |
| `nerdcommenter` | Remove | -- | Neovim 0.10+ has built-in `gc` commenting |
| `vim-easy-align` | Keep | -- | No better Lua alternative exists |
| `vim-indent-object` | Keep | -- | Or replace with treesitter textobjects |
| `delimitMate` | Replace | `mini.pairs` or `nvim-autopairs` | Lua-native auto-pairs |
| `vim-unimpaired` | Keep | -- | `[q`, `]q`, `[b`, `]b` etc. still useful |
| `vim-abolish` | Keep | -- | `:Subvert` and coercion (`crs`, `crc`) |
| `vim-ragtag` | Keep | -- | HTML/template tag helpers |
| `vim-rsi` | Keep | -- | Readline keybindings in insert/cmdline |
| `gundo.vim` | Remove | -- | Neovim has persistent undo + `undofile` |
| `editorconfig-vim` | Remove | -- | Neovim 0.9+ has built-in EditorConfig |
| -- | New | `conform.nvim` | Async formatting on save |
| -- | New | `nvim-lint` | Async linting (non-LSP linters) |

## Completion & Snippets

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `nvim-cmp` | Keep | -- | Already installed; needs proper config |
| `cmp-nvim-lsp` | Keep | -- | LSP completion source |
| `cmp-buffer` | Keep | -- | Buffer word completion source |
| `cmp-path` | Keep | -- | File path completion source |
| `cmp-cmdline` | Keep | -- | Command-line completion source |
| `vim-vsnip` + `cmp-vsnip` | Replace | `LuaSnip` + `cmp_luasnip` | More capable, better community support |
| -- | New | `friendly-snippets` | Community snippet collection |

## LSP & Diagnostics

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `nvim-lspconfig` | Keep | -- | Already installed; needs server configs |
| `syntastic` | Remove | -- | LSP + nvim-lint replaces this entirely |
| -- | New | `mason.nvim` | Auto-install language servers |
| -- | New | `mason-lspconfig.nvim` | Bridge mason + lspconfig |

## Language Support

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `nvim-treesitter` | Keep | -- | Already installed; add more parsers |
| `nvim-treesitter-textobjects` | Keep | -- | Already installed |
| `vim-ruby` | Keep | -- | Ruby-specific motions beyond treesitter |
| `vim-rails` | Keep | -- | `:Emodel`, `:Econtroller`, etc. |
| `vim-bundler` | Keep | -- | Gemfile integration |
| `vim-javascript` | Remove | -- | Treesitter handles JS syntax |
| `vim-jsx` | Remove | -- | Treesitter handles JSX |
| `vim-json` | Remove | -- | Treesitter handles JSON |
| `vim-markdown` | Remove | -- | Treesitter handles Markdown |
| `vim-toml` | Remove | -- | Treesitter handles TOML |
| `Dockerfile.vim` | Remove | -- | Treesitter handles Dockerfile |
| `vim-terraform` | Remove | -- | Treesitter + terraformls |
| `rust.vim` | Keep/Replace | `rustaceanvim` | Consider for full Rust IDE features |
| `csv.vim` | Keep | -- | No treesitter equivalent for CSV |
| `emmet-vim` | Keep | -- | HTML expansion, no Lua replacement |
| `vim-endwise` | Keep | -- | `nvim-treesitter-endwise` incompatible with new treesitter API |
| `vim-rbenv` | Remove | -- | Shell handles Ruby version |
| -- | New | `nvim-treesitter-context` | Shows enclosing function/class at top |

## Other

| Old Plugin | Action | New Plugin | Notes |
|---|---|---|---|
| `vim-tmux-navigator` | Keep | -- | Still the best tmux/nvim navigator |
| `vim-dispatch` | Keep | -- | Async `:Make`, `:Dispatch` |
| `vim-projectionist` | Keep | -- | Alternate file navigation |
| `vim-plugin-AnsiEsc` | Remove | -- | Rarely needed with modern terminal |
| -- | New | `toggleterm.nvim` | Toggle terminal with a keypress |
| -- | New | `persistence.nvim` | Auto-save/restore sessions |
| -- | New | `nvim-notify` | Toast notifications for LSP progress |

---

## Summary

| Action | Count |
|--------|-------|
| Keep (as-is) | 18 |
| Replace | 10 |
| Remove | 17 |
| New (no old equivalent) | 16 |

## Checklist

- [ ] Review this table -- adjust any keep/replace/remove decisions
- [ ] Use this as a reference while working through each chapter
- [ ] After migration, verify no old plugins are still being loaded
