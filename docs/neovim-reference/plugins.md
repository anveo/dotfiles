# Installed Plugins

What's in the box. Grouped by category.

---

## Navigation & Search

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [flash.nvim](https://github.com/folke/flash.nvim) | Motion plugin -- type chars to jump anywhere on screen with labels | `s`, `S`, `<Leader>j/k` |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder for files, grep, buffers, and everything else | `<C-p>`, `<Leader>f`, `<C-b>` |
| [telescope-fzf-native.nvim](https://github.com/nvim-telescope/telescope-fzf-native.nvim) | Native FZF sorter for telescope (faster fuzzy matching) | (automatic) |
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | File explorer sidebar with git status indicators | `<Leader>d`, `<Leader>D` |
| [vim-projectionist](https://github.com/tpope/vim-projectionist) | Alternate file navigation with global heuristics for Ruby, TS, JS projects | `:A`, `:AV`, `:Esource`, `:Espec` |

## Editing & Text Manipulation

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [vim-surround](https://github.com/tpope/vim-surround) | Add, change, delete surrounding pairs (quotes, brackets, tags) | `ys`, `cs`, `ds` |
| [vim-easy-align](https://github.com/junegunn/vim-easy-align) | Align text on any character | `:'<,'>EasyAlign` |
| [vim-abolish](https://github.com/tpope/vim-abolish) | Case coercion and case-preserving substitution | `crs`, `crc`, `crm`, `:Subvert` |
| [vim-indent-object](https://github.com/michaeljsmith/vim-indent-object) | Text object for indentation levels | `aI`, `iI` (capital I for strict) |
| [vim-repeat](https://github.com/tpope/vim-repeat) | Makes `.` repeat work with surround, abolish, unimpaired, etc. | `.` |
| [vim-unimpaired](https://github.com/tpope/vim-unimpaired) | Bracket mappings for quickfix, buffers, lines, encoding | `]q`, `[q`, `]b`, `[b`, etc. |
| [vim-rsi](https://github.com/tpope/vim-rsi) | Readline (emacs) keybindings in insert and command-line mode | `<C-a>`, `<C-e>`, `<C-k>` |
| [vim-ragtag](https://github.com/tpope/vim-ragtag) | HTML/template tag helpers (close tags, encode entities) | `<C-x>/`, `<C-x>=`, etc. |
| [emmet-vim](https://github.com/mattn/emmet-vim) | HTML expansion from abbreviations | `<C-y>,` to expand |
| [vim-endwise](https://github.com/tpope/vim-endwise) | Auto-insert `end` after `def`, `do`, `if` in Ruby, Lua, etc. | (automatic on `<CR>`) |

## Treesitter

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax-aware highlighting, folding, indentation | (automatic) |
| [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) | Select, move between, and swap functions/classes/parameters | `af`, `if`, `]f`, `<Leader>a` |
| [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) | Sticky header showing enclosing function/class at screen top | (automatic, up to 3 lines) |

## LSP & Diagnostics

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP client configuration for all language servers | `gd`, `gr`, `K`, `<Leader>rn` |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | Auto-install language servers, formatters, linters | `:Mason` to manage |
| [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) | Bridge between mason and lspconfig (ensure_installed) | (automatic) |

## Completion & Snippets

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Autocompletion engine with multiple sources | `<Tab>`, `<CR>`, `<C-Space>` |
| [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) | LSP completion source for nvim-cmp | (automatic) |
| [cmp-buffer](https://github.com/hrsh7th/cmp-buffer) | Buffer word completion source | (automatic) |
| [cmp-path](https://github.com/hrsh7th/cmp-path) | File path completion source | (automatic) |
| [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline) | Command-line and search completion | (automatic in `:` and `/`) |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine with VS Code and snipmate support | `<Tab>` to expand/jump |
| [cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) | LuaSnip completion source for nvim-cmp | (automatic) |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | Large collection of VS Code-style snippets for many languages | (automatic via LuaSnip) |

## Formatting & Linting

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Format on save with per-language formatters | `<Leader>bf`, auto on save |
| [nvim-lint](https://github.com/mfussenegger/nvim-lint) | Async linting on save (most linting delegated to LSP) | (automatic) |

## Git

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [vim-fugitive](https://github.com/tpope/vim-fugitive) | Git wrapper -- staging, committing, blaming, browsing | `:G`, `:G blame`, `:G log` |
| [vim-rhubarb](https://github.com/tpope/vim-rhubarb) | GitHub integration for fugitive (`:GBrowse` opens GitHub) | `:GBrowse` |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git hunk signs, stage/reset hunks, line blame | `]h`, `<Leader>hs`, `<Leader>gb` |
| [diffview.nvim](https://github.com/sindrets/diffview.nvim) | Side-by-side diff viewer and file history browser | `<Leader>gd`, `<Leader>gh` |

## UI & Appearance

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [jellybeans.nvim](https://github.com/wtfox/jellybeans.nvim) | Colorscheme (treesitter-aware port of jellybeans) | (automatic) |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline showing mode, branch, diff, diagnostics, file | (automatic) |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Popup showing available keybindings after pressing a prefix | Press `<Leader>` and wait |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indent guide lines with scope highlighting | (automatic) |
| [dressing.nvim](https://github.com/stevearc/dressing.nvim) | Better UI for rename prompts, code actions, selects | (automatic) |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File type icons for telescope, neo-tree, lualine | (automatic) |
| [nvim-colorizer.lua](https://github.com/norcalli/nvim-colorizer.lua) | Inline color previews for hex codes, CSS colors | (automatic) |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlight and search TODO/FIXME/HACK comments | `]t`, `[t`, `<Leader>ft` |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | Toggle a terminal drawer without leaving neovim | `<C-\>` |

## Language-Specific

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [vim-ruby](https://github.com/vim-ruby/vim-ruby) | Enhanced Ruby syntax, indentation, compilation | (automatic for .rb) |
| [vim-rails](https://github.com/tpope/vim-rails) | Rails navigation, generators, `gf` on partials/models | `:Econtroller`, `:Emodel`, `:A`, `gf` |
| [vim-bundler](https://github.com/tpope/vim-bundler) | Bundler integration, `gf` on gem names in Gemfile | `gf` on gem name |
| [csv.vim](https://github.com/chrisbra/csv.vim) | CSV column highlighting, filtering, sorting | `:CSVTable`, column navigation |

## Database

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [vim-dadbod](https://github.com/tpope/vim-dadbod) | Database client -- run SQL queries from neovim | `:DB {query}` |
| [vim-dadbod-ui](https://github.com/kristijanhusak/vim-dadbod-ui) | Database explorer UI with table browsing and saved queries | `<Leader>db`, `:DBUI` |
| [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion) | SQL autocompletion against your actual schema (via nvim-cmp) | (automatic in SQL buffers) |

## Infrastructure

| Plugin | What it does | Key commands |
|--------|-------------|--------------|
| [vim-dispatch](https://github.com/tpope/vim-dispatch) | Async `:Make` and `:Dispatch` (run commands in background) | `:Make`, `:Dispatch rspec %` |
| [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless `<C-h/j/k/l>` navigation between tmux and neovim panes | `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>` |
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Lua utility library (dependency for telescope, gitsigns, etc.) | (library) |
| [nui.nvim](https://github.com/MunifTanjim/nui.nvim) | UI component library (dependency for neo-tree) | (library) |
