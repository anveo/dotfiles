# 07 -- Treesitter Deep-Dive, Languages, Snippets

## Treesitter Beyond Syntax Highlighting

Your existing `nvimfiles/` has basic treesitter with highlight + textobjects. There's much more to enable.

### Plugin spec: `lua/plugins/treesitter.lua`

> **Breaking change (2025):** nvim-treesitter switched from `master` to `main` branch and
> removed the `require("nvim-treesitter.configs").setup()` API entirely. The new approach:
> - Install parsers via `require("nvim-treesitter").install({...})`
> - Enable highlighting per-filetype via `vim.treesitter.start()` in a `FileType` autocmd
> - Enable indentation via `vim.bo.indentexpr`
> - The plugin does **not** support lazy-loading (`lazy = false`)
>
> See: https://github.com/nvim-treesitter/nvim-treesitter (main branch README)

```lua
return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "ruby", "javascript", "typescript", "tsx",
        "go", "rust", "python", "lua",
        "json", "yaml", "toml", "html", "css",
        "markdown", "markdown_inline",
        "bash", "dockerfile", "terraform", "hcl",
        "gitcommit", "gitrebase",
        "vim", "vimdoc", "query",
        "regex", "sql",
      }

      require("nvim-treesitter").install(parsers)

      -- Enable treesitter highlighting and indentation for all filetypes
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterSetup", { clear = true }),
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- Textobjects (also moved to main branch with new API)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local ts_select = require("nvim-treesitter-textobjects.select")
      local ts_move = require("nvim-treesitter-textobjects.move")
      local ts_swap = require("nvim-treesitter-textobjects.swap")

      require("nvim-treesitter-textobjects").setup({
        select = { lookahead = true },
        move = { set_jumps = true },
      })

      -- Select textobjects
      local select_maps = {
        ["af"] = "@function.outer", ["if"] = "@function.inner",
        ["ac"] = "@class.outer",    ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner",
        ["ai"] = "@conditional.outer", ["ii"] = "@conditional.inner",
        ["al"] = "@loop.outer",     ["il"] = "@loop.inner",
        ["ab"] = "@block.outer",    ["ib"] = "@block.inner",
      }
      for key, query in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          ts_select.select_textobject(query, "textobjects")
        end, { desc = query })
      end

      -- Move: next/prev start/end
      for key, query in pairs({ ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.outer" }) do
        vim.keymap.set({ "n", "x", "o" }, key, function() ts_move.goto_next_start(query, "textobjects") end)
      end
      for key, query in pairs({ ["]F"] = "@function.outer", ["]C"] = "@class.outer" }) do
        vim.keymap.set({ "n", "x", "o" }, key, function() ts_move.goto_next_end(query, "textobjects") end)
      end
      for key, query in pairs({ ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.outer" }) do
        vim.keymap.set({ "n", "x", "o" }, key, function() ts_move.goto_previous_start(query, "textobjects") end)
      end
      for key, query in pairs({ ["[F"] = "@function.outer", ["[C"] = "@class.outer" }) do
        vim.keymap.set({ "n", "x", "o" }, key, function() ts_move.goto_previous_end(query, "textobjects") end)
      end

      -- Swap parameters
      vim.keymap.set("n", "<Leader>a", function() ts_swap.swap_next("@parameter.inner") end, { desc = "Swap parameter with next" })
      vim.keymap.set("n", "<Leader>A", function() ts_swap.swap_previous("@parameter.inner") end, { desc = "Swap parameter with previous" })
    end,
  },

  -- Sticky context: show enclosing function/class at top of screen
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      max_lines = 3,
    },
  },

  -- Endwise: auto-insert "end" in Ruby, Lua, etc.
  -- Using vim-endwise since nvim-treesitter-endwise is incompatible with the new treesitter API
  { "tpope/vim-endwise" },
}
```

> **Dropped from old config:** Incremental selection (`<Leader>ss/si/sc/sd`) was part of the
> removed `nvim-treesitter.configs` API. Use flash.nvim's `S` (treesitter select) as an alternative.

### Smart Folding with Treesitter

Add to `lua/options.lua`:

```lua
-- Treesitter-based folding (upgrade from indent-based)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99        -- start with all folds open
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true
```

This replaces the `foldmethod=indent` from the old config. Treesitter folding knows about language structure -- it folds functions, classes, and blocks correctly even when indentation is inconsistent.

### Textobject Quick Reference

| Textobject | Inner | Outer | What It Selects |
|---|---|---|---|
| Function | `if` | `af` | Function body / entire function |
| Class | `ic` | `ac` | Class body / entire class |
| Parameter | `ia` | `aa` | Single parameter / with separator |
| Conditional | `ii` | `ai` | If body / entire if block |
| Loop | `il` | `al` | Loop body / entire loop |
| Block | `ib` | `ab` | Block body / entire block |

**Usage examples:**
- `daf` -- delete entire function
- `yic` -- yank class body
- `via` -- select a parameter
- `cif` -- change function body

### Movement Keybindings

| Binding | Action |
|---|---|
| `]f` / `[f` | Next/prev function start |
| `]c` / `[c` | Next/prev class start |
| `]a` / `[a` | Next/prev parameter |
| `<Leader>a` | Swap parameter with next |
| `<Leader>A` | Swap parameter with previous |

> **Note:** `<Leader>a` was previously mapped to vim-easy-align. If you keep easy-align, remap the parameter swap to `<Leader>sa` or similar.

## Language Plugins to Remove

Treesitter replaces these syntax/indent plugins:

| Plugin | Treesitter Parser |
|--------|-------------------|
| `pangloss/vim-javascript` | `javascript`, `typescript`, `tsx` |
| `mxw/vim-jsx` | `tsx` |
| `elzr/vim-json` | `json` |
| `tpope/vim-markdown` | `markdown`, `markdown_inline` |
| `cespare/vim-toml` | `toml` |
| `ekalinin/Dockerfile.vim` | `dockerfile` |
| `markcornick/vim-terraform` | `terraform`, `hcl` |

## Language Plugins to Keep

| Plugin | Why |
|--------|-----|
| `vim-ruby/vim-ruby` | Ruby-specific motions (`]m`, `[m`), `%` matching beyond treesitter |
| `tpope/vim-rails` | `:Emodel`, `:Econtroller`, `:Eview` navigation |
| `tpope/vim-bundler` | Gemfile integration, `:Bundle` |
| `mattn/emmet-vim` | HTML expansion (`div.foo>ul>li*3` + `<C-e>,`) |
| `chrisbra/csv.vim` | CSV-specific column operations |

### Consider: rustaceanvim

If you do significant Rust work, `mrcjkb/rustaceanvim` provides:
- Integrated cargo commands
- Inlay hints (type annotations)
- Debugger integration
- Better rust-analyzer integration than vanilla lspconfig

```lua
{
  "mrcjkb/rustaceanvim",
  version = "^5",
  ft = { "rust" },
}
```

## Plugins to Remove

| Plugin | Reason |
|--------|--------|
| `tpope/vim-rbenv` | Shell handles Ruby version; adds startup cost |

> **Note:** `tpope/vim-endwise` is **kept** (not replaced). `nvim-treesitter-endwise` is
> incompatible with the new treesitter `main` branch API.

## ftplugin Porting

Create these files in `nvimfiles/after/ftplugin/`:

### `after/ftplugin/ruby.lua`

```lua
-- 2-space indent for Ruby (overrides the 4-space default)
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2

-- String interpolation helper: # inside double-quotes becomes #{}
-- Port from vimfiles/ftplugin/ruby.vim
vim.keymap.set("i", "#", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local before = line:sub(1, col - 1)
  local after = line:sub(col)
  if before:find('"') and after:find('"') then
    return "#{}<Left>"
  else
    return "#"
  end
end, { buffer = true, expr = true })

-- Surround with # (for vim-surround)
if vim.g.loaded_surround then
  vim.b["surround_" .. string.byte("#")] = "#{\\r}"
end
```

### `after/ftplugin/go.lua`

```lua
-- Go uses hard tabs, 4-space width
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.list = false
```

### `after/ftplugin/javascript.lua`

```lua
-- 2-space indent for JavaScript
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2
```

### Dropped ftplugins

| File | Reason |
|------|--------|
| `ftplugin/coffee.vim` | CoffeeScript is dead |
| `ftplugin/php.vim` | Contents were all commented out |
| `ftplugin/processing.vim` | Not using Processing |

## LuaSnip + friendly-snippets

### Community Snippets

`friendly-snippets` provides snippets for most languages out of the box. These are loaded in the completion config ([04-lsp-and-completion](04-lsp-and-completion.md)):

```lua
require("luasnip.loaders.from_vscode").lazy_load()
```

### Porting Custom Ruby/RSpec Snippets

Your `vimfiles/_snippets/ruby.snippets` has 107 lines of custom rspec snippets. These are snipmate format and can be loaded directly by LuaSnip.

1. Create `nvimfiles/snippets/ruby.snippets` (copy from `vimfiles/_snippets/ruby.snippets`)
2. Create `nvimfiles/snippets/_.snippets` (copy from `vimfiles/_snippets/_.snippets`)
3. Load them in LuaSnip config:

```lua
require("luasnip.loaders.from_snipmate").lazy_load({ paths = { "./snippets" } })
```

**Key snippets preserved:**

| Trigger | Expansion | Used For |
|---------|-----------|----------|
| `desc` | `describe ... do ... end` | RSpec describe blocks |
| `cont` | `context '...' do ... end` | RSpec context blocks |
| `it` | `it '...' do ... end` | RSpec examples |
| `let` | `let(:obj) { ... }` | RSpec let declarations |
| `exp` | `expect(obj).to ...` | RSpec expectations |
| `bef` | `before :each do ... end` | RSpec setup |
| `pry` | `require 'pry'; binding.pry` | Debugging |
| `def` | `def method_name ... end` | Ruby methods |

The `date`, `datetime`, `lorem` snippets from `_.snippets` are already included in friendly-snippets, but your versions will take precedence if loaded after.

## nvim-treesitter-context

Shows the enclosing function/class name pinned to the top of the screen when you scroll deep into a long function. Extremely useful for navigating large files.

No configuration needed beyond what's in the plugin spec above. Disable per-buffer with `:TSContextToggle`.

## Checklist

- [ ] Update `lua/plugins/treesitter.lua` with full config (new `main` branch API)
- [ ] Add treesitter-context and vim-endwise plugins
- [ ] Update `lua/options.lua` with treesitter folding settings
- [ ] Create `after/ftplugin/ruby.lua`
- [ ] Create `after/ftplugin/go.lua`
- [ ] Create `after/ftplugin/javascript.lua`
- [ ] Copy snippet files to `nvimfiles/snippets/`
- [ ] Add snipmate loader to LuaSnip config
- [ ] Remove vim-javascript, vim-jsx, vim-json, vim-markdown, vim-toml, Dockerfile.vim, vim-terraform from plugin list
- [ ] Parsers install automatically via `require("nvim-treesitter").install()`
- [ ] Test: open a Ruby file, verify 2-space indent
- [ ] Test: open a Go file, verify hard tabs
- [ ] Test: `daf` deletes an entire function
- [ ] Test: `]f` jumps to next function
- [ ] Test: `<Leader>a` swaps parameters
- [ ] Test: treesitter-context shows function name at top of screen
- [ ] Test: pressing Enter after `def foo` auto-inserts `end` (endwise)
- [ ] Test: `:it<Tab>` expands rspec `it` snippet
- [ ] Test: `zc` folds a function (treesitter folding)
