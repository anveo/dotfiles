# 08 -- Things You Didn't Know Neovim Could Do

Capabilities that have no equivalent in your old config. These aren't migrations -- they're net-new features.

## Inlay Hints (Neovim 0.10+)

Language servers can show inferred types, parameter names, and other hints inline in your code, rendered as virtual text:

```go
// Without inlay hints:
x := computeValue(cfg, true)

// With inlay hints:
x: int := computeValue(cfg: Config, verbose: true)
//  ^^^                     ^^^^^^   ^^^^^^^^
//  These appear as dimmed virtual text, not actual code
```

### Enable globally

Add to your LSP `on_attach` callback (in `lua/plugins/lsp.lua`):

```lua
-- Inside the LspAttach autocmd callback:
if client and client.supports_method("textDocument/inlayHint") then
  map("<Leader>ih", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
  end, "Toggle inlay hints")
end
```

**Best for:** Go (`gopls`), Rust (`rust_analyzer`), TypeScript (`ts_ls`). Less useful for Ruby and Python.

## Built-in Terminal + toggleterm.nvim

Neovim has a built-in terminal emulator (`:terminal`). toggleterm makes it practical:

```lua
-- Add to lua/plugins/ui.lua or create lua/plugins/terminal.lua
{
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-\\>", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
    { "<C-\\>", "<cmd>ToggleTerm<CR>", mode = "t", desc = "Toggle terminal" },
  },
  opts = {
    size = function(term)
      if term.direction == "horizontal" then return 15
      elseif term.direction == "vertical" then return vim.o.columns * 0.4
      end
    end,
    open_mapping = [[<C-\>]],
    direction = "horizontal",   -- or "vertical", "float", "tab"
    shade_terminals = true,
    float_opts = {
      border = "curved",
    },
  },
}
```

**Usage:**
- `<C-\>` toggles a terminal split
- Multiple terminals: `2<C-\>` opens terminal #2
- Inside terminal: `<C-\>` hides it (state preserved)

This replaces switching to a tmux pane for quick commands -- the terminal lives inside neovim with full copy/paste integration.

## Floating Windows

Your old config couldn't do this. Neovim renders floating windows for:

- **Hover docs** (`K` in LSP) -- documentation appears in a float
- **Signature help** -- parameter info as you type function arguments
- **Diagnostic popups** (`<Leader>e`) -- full error message in a float
- **Telescope** -- all pickers render in floating windows
- **Completion docs** -- nvim-cmp shows documentation alongside completions

These just work with the LSP and completion config from chapter 04. No extra setup needed.

## Lazy-Loading

lazy.nvim loads plugins on demand. Your old vim-plug config loaded all 60+ plugins at startup. With lazy.nvim:

```lua
-- Loads only when you open a Rust file:
{ "mrcjkb/rustaceanvim", ft = "rust" }

-- Loads only when you run the command:
{ "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewFileHistory" } }

-- Loads only when you press the key:
{ "nvim-neo-tree/neo-tree.nvim", keys = { { "<Leader>d", "<cmd>Neotree toggle<CR>" } } }

-- Loads after UI renders (non-blocking):
{ "folke/which-key.nvim", event = "VeryLazy" }
```

### Profiling Startup

`:Lazy profile` shows exactly how long each plugin takes to load. Use it to find bottlenecks.

Target: **<50ms** total startup time (your current vim-plug config is likely 200-500ms).

## Persistent Undo

Undo history survives restarts. Add to `lua/options.lua`:

```lua
vim.opt.undofile = true
-- undodir defaults to ~/.local/state/nvim/undo/ (no config needed)
```

Now you can undo changes from yesterday. gundo.vim is no longer needed -- the undo tree is persistent. If you want a visual undo tree browser, `mbbill/undotree` is the modern replacement (but you may not need it).

## `inccommand=split` (Already Configured)

Your `nvimfiles/lua/options.lua` already has this:

```lua
vim.opt.inccommand = "split"
```

This shows a live preview of `:s/old/new/` substitutions in a split window. Every match highlights as you type, and the split shows what will change in the full file. This is a neovim-exclusive feature with no Vim equivalent.

## Session Management

Auto-save and restore your session (open buffers, window layout, cursor positions):

```lua
-- Add to lua/plugins/ui.lua
{
  "folke/persistence.nvim",
  event = "BufReadPre",
  keys = {
    { "<Leader>qs", function() require("persistence").load() end, desc = "Restore session" },
    { "<Leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<Leader>qd", function() require("persistence").stop() end, desc = "Don't save session" },
  },
  opts = {},
}
```

Sessions are saved per-directory. Open neovim in a project, work, close. Next time you open neovim in that directory, `<Leader>qs` restores everything.

## Harpoon v2

Quick-access bookmarks for your most-used files in a project. Faster than telescope for your "top 4" files:

```lua
-- Add to lua/plugins/navigation.lua or create lua/plugins/harpoon.lua
{
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<Leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
    { "<Leader>hh", function()
      local harpoon = require("harpoon")
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, desc = "Harpoon menu" },
    { "<Leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
    { "<Leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
    { "<Leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
    { "<Leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
  },
  opts = {},
}
```

**Usage:** Mark files with `<Leader>ha`. Switch instantly with `<Leader>1-4`. View/reorder with `<Leader>hh`.

## Built-in Commenting (Neovim 0.10+)

Neovim 0.10 has native commenting built in. The `gc` operator works without any plugin:

- `gcc` -- toggle comment current line
- `gc{motion}` -- toggle comment over motion (e.g., `gcap` for paragraph)
- `gc` in visual mode -- toggle comment selection

This replaces both `vim-commentary` and `nerdcommenter`. The built-in version is treesitter-aware, so it picks the right comment syntax even in embedded languages (e.g., `<script>` inside HTML).

## Remote Editing

Neovim can run as a server and accept remote commands:

```bash
# Start server
nvim --listen /tmp/nvim.sock

# Open a file in the running instance (from another terminal)
nvim --server /tmp/nvim.sock --remote file.txt
```

Useful when you want git commit messages or other `$EDITOR` invocations to open in your existing neovim instance instead of spawning a new one.

## nvim-notify

Toast notifications for background events:

```lua
-- Add to lua/plugins/ui.lua
{
  "rcarriga/nvim-notify",
  event = "VeryLazy",
  config = function()
    vim.notify = require("notify")
  end,
  opts = {
    timeout = 3000,
    max_height = function() return math.floor(vim.o.lines * 0.75) end,
    max_width = function() return math.floor(vim.o.columns * 0.75) end,
  },
}
```

Shows notifications for LSP progress ("Indexing workspace..."), formatting, linting, and any `vim.notify()` calls. Replaces the easy-to-miss messages at the bottom of the screen.

## Checklist

- [ ] Enable `undofile` in options.lua
- [ ] Add inlay hint toggle to LSP on_attach
- [ ] Install toggleterm.nvim
- [ ] Test: `<C-\>` toggles a terminal
- [ ] Test: `K` shows hover docs in a float
- [ ] Test: `:Lazy profile` shows startup time <50ms
- [ ] Test: close and reopen nvim, verify undo history persists
- [ ] Test: `:s/foo/bar/g` shows live preview in split
- [ ] Test: `gcc` toggles a comment (no plugin needed)
- [ ] Optional: install persistence.nvim for session management
- [ ] Optional: install harpoon for file bookmarks
- [ ] Optional: install nvim-notify for toast notifications
