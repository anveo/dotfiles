# 03 -- Fuzzy Finding, File Browser, Motion

This chapter replaces five plugins with three: telescope.nvim, neo-tree.nvim, flash.nvim.

## telescope.nvim

**Replaces:** ctrlp.vim, fzf + fzf.vim, ack.vim, bufexplorer

### Plugin spec: `lua/plugins/telescope.lua`

```lua
return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",  -- 0.1.x is incompatible with Neovim 0.11 (ft_to_lang removed)
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
      "nvim-web-devicons",
    },
    cmd = "Telescope",
    keys = {
      { "<C-P>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<C-F>", "<cmd>Telescope git_files<CR>", desc = "Git files" },
      { "<Leader>f", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<Leader>ff", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<Leader>F", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      { "<C-B>", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<Leader><Tab>", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
      { "<Leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<Leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<Leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<Leader>fg", "<cmd>Telescope git_status<CR>", desc = "Git status" },
      { "<Leader>fc", "<cmd>Telescope git_commits<CR>", desc = "Git commits" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")

      telescope.setup({
        defaults = {
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = { preview_width = 0.55 },
            width = 0.9,
            height = 0.9,
          },
          mappings = {
            i = {
              ["<Esc>"] = actions.close,            -- single Esc to close
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            },
          },
          file_ignore_patterns = {
            "node_modules/", ".git/", "vendor/", "coverage/", "tmp/",
            "%.png", "%.jpg", "%.gif", "%.pdf", "%.zip",
          },
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case", "--hidden",
            "--glob", "!.git/",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git/" },
          },
          buffers = {
            sort_mru = true,
            ignore_current_buffer = true,
          },
        },
      })

      telescope.load_extension("fzf")
    end,
  },
}
```

### Keybinding Migration

| Old Binding | Old Plugin | New Binding | Telescope Picker |
|---|---|---|---|
| `<C-P>` | ctrlp.vim | `<C-P>` | `find_files` |
| `<C-F>` | fzf.vim `:GFiles` | `<C-F>` | `git_files` |
| `<Leader>f` | ack.vim `:Ack!` | `<Leader>f` | `live_grep` |
| `<Leader>F` | ack.vim word search | `<Leader>F` | `grep_string` |
| `<C-B>` | bufexplorer | `<C-B>` | `buffers` |
| `<Leader><Tab>` | fzf-maps | `<Leader><Tab>` | `keymaps` |

### Bonus Pickers (no old equivalent)

- `<Leader>fh` -- search help tags
- `<Leader>fd` -- browse diagnostics
- `<Leader>fr` -- recent files (oldfiles)
- `<Leader>fg` -- git status (changed files)
- `<Leader>fc` -- git commit log

> **Note:** `<Leader>fc` was previously "find merge conflict markers" in mappings.vim. If you prefer to keep that, remap git commits to `<Leader>fgc` or similar.

## neo-tree.nvim

**Replaces:** NERDTree

### Plugin spec: `lua/plugins/neo-tree.lua`

```lua
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<Leader>d", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
      { "<Leader>D", "<cmd>Neotree reveal<CR>", desc = "Reveal current file in tree" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          filtered_items = {
            visible = true,        -- show hidden files (dimmed)
            hide_dotfiles = false,  -- match NERDTree's ShowHidden
            hide_gitignored = true,
            hide_by_name = {
              ".DS_Store",
              ".git",
              ".svn",
              ".sass-cache",
            },
          },
          follow_current_file = {
            enabled = true,
          },
          use_libuv_file_watcher = true,
        },
        window = {
          position = "left",
          width = 35,
        },
        git_status = {
          symbols = {
            added     = "",
            modified  = "",
            deleted   = "",
            renamed   = "➜",
            untracked = "★",
          },
        },
      })
    end,
  },
}
```

### NERDTree Settings Ported

| NERDTree Setting | neo-tree Equivalent |
|---|---|
| `NERDTreeShowHidden = 1` | `hide_dotfiles = false` |
| `NERDTreeShowBookmarks = 1` | Built-in bookmark support |
| `NERDTreeIgnore = ['\~$', '.svn$', ...]` | `hide_by_name` |
| `<Leader>d` toggle | `<Leader>d` toggle |

### New capabilities over NERDTree

- Git status indicators in the tree
- Fuzzy finder within the tree (`/` to search)
- Floating window option (`window.position = "float"`)
- Built-in file operations (rename, move, copy, delete)
- `<Leader>D` reveals the current file in the tree

## flash.nvim

**Replaces:** vim-easymotion

### Plugin spec: `lua/plugins/flash.lua`

```lua
return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "<Leader>j", mode = { "n", "x", "o" }, function()
        require("flash").jump({
          search = { mode = "search", max_length = 0 },
          label = { after = { 0, 0 } },
          pattern = "^",
        })
      end, desc = "Jump to line" },
      { "<Leader>k", mode = { "n", "x", "o" }, function()
        require("flash").jump({
          search = { mode = "search", max_length = 0, forward = false },
          label = { after = { 0, 0 } },
          pattern = "^",
        })
      end, desc = "Jump to line (up)" },
    },
    opts = {
      modes = {
        search = {
          enabled = false,  -- do NOT override native / search (fixes the easymotion conflict)
        },
        char = {
          enabled = true,   -- enhanced f/t/F/T motions
        },
      },
    },
  },
}
```

### EasyMotion Migration

| Old Binding | EasyMotion Action | New Binding | flash.nvim Action |
|---|---|---|---|
| `s` | 2-char search (`easymotion-s2`) | `s` | `flash.jump()` (type chars, pick label) |
| `<Leader>j` | Line motion down | `<Leader>j` | Jump to line (down) |
| `<Leader>k` | Line motion up | `<Leader>k` | Jump to line (up) |
| `<Leader>ew` | Word motion | `s` then type | Flash handles this naturally |
| `/` | EasyMotion search (overrode native!) | `/` | **Native search restored.** Use `s` for flash. |

### Key Improvement: `/` is native again

The old config had this in `plugins.vim`:

```vim
map  / <Plug>(easymotion-sn)
omap / <Plug>(easymotion-tn)
```

This **completely replaced** Vim's native incremental search with EasyMotion's search. Flash does NOT do this by default (`search.enabled = false`). You get:

- `/` -- native incremental search with `incsearch` highlighting
- `s` -- flash.nvim jump (the good part of easymotion)

### New: treesitter-aware selection

`S` in flash.nvim uses treesitter to label and select syntax nodes. Press `S`, then pick a label to visually select an entire function, class, block, etc. This has no easymotion equivalent.

## Plugins to Remove

After this chapter, these plugins are fully replaced:

| Plugin | Status |
|--------|--------|
| `ctrlpvim/ctrlp.vim` | Replaced by telescope `find_files` |
| `junegunn/fzf` + `junegunn/fzf.vim` | Replaced by telescope + fzf-native |
| `mileszs/ack.vim` | Replaced by telescope `live_grep` |
| `jlanzarotta/bufexplorer` | Replaced by telescope `buffers` |
| `scrooloose/nerdtree` | Replaced by neo-tree |
| `Lokaltog/vim-easymotion` | Replaced by flash.nvim |
| `regedarek/ZoomWin` | Dropped (use `<C-w>o` or write a simple toggle) |

## Checklist

- [ ] Create `lua/plugins/telescope.lua`
- [ ] Create `lua/plugins/neo-tree.lua`
- [ ] Create `lua/plugins/flash.lua`
- [ ] Remove old keymaps for ctrlp, fzf, ack, bufexplorer, NERDTree, easymotion from `keymaps.lua`
- [ ] Test: `<C-P>` opens telescope file finder
- [ ] Test: `<C-F>` opens telescope git files
- [ ] Test: `<Leader>f` opens live grep
- [ ] Test: `<C-B>` shows buffer list
- [ ] Test: `<Leader>d` toggles neo-tree sidebar
- [ ] Test: `s` triggers flash.nvim jump
- [ ] Test: `/` still does native incremental search
- [ ] Test: `S` does treesitter selection in a code file
- [ ] Verify telescope respects `file_ignore_patterns` (no node_modules, .git)
