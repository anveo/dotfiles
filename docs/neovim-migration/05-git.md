# 05 -- Git Integration

## Keep: vim-fugitive + vim-rhubarb

These are still the best git plugins, period. No Lua replacement matches fugitive's `:Git` interface.

### Plugin spec: `lua/plugins/git.lua`

```lua
return {
  -- Fugitive: the git plugin
  { "tpope/vim-fugitive" },

  -- GitHub integration for :GBrowse
  { "tpope/vim-rhubarb" },

  -- Gitsigns: replaces vim-gitgutter
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = "▎" },
        change       = { text = "▎" },
        delete       = { text = "" },
        topdelete    = { text = "" },
        changedelete = { text = "▎" },
        untracked    = { text = "▎" },
      },
      current_line_blame = false,   -- toggle with <Leader>gb
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        -- Navigation between hunks
        map("n", "]h", gs.next_hunk, "Next hunk")
        map("n", "[h", gs.prev_hunk, "Previous hunk")

        -- Actions
        map("n", "<Leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<Leader>hr", gs.reset_hunk, "Reset hunk")
        map("v", "<Leader>hs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage selected")
        map("v", "<Leader>hr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset selected")
        map("n", "<Leader>hS", gs.stage_buffer, "Stage buffer")
        map("n", "<Leader>hR", gs.reset_buffer, "Reset buffer")
        map("n", "<Leader>hu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<Leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<Leader>gb", gs.toggle_current_line_blame, "Toggle line blame")
        map("n", "<Leader>hd", gs.diffthis, "Diff this file")
        map("n", "<Leader>hD", function() gs.diffthis("~") end, "Diff against HEAD~")

        -- Text object: select hunk
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
      end,
    },
  },

  -- Diffview: side-by-side diff viewer
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<Leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Git diff" },
      { "<Leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
      { "<Leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Branch history" },
    },
    opts = {
      enhanced_diff_hl = true,
    },
  },
}
```

## gitgutter -> gitsigns Migration

| Feature | vim-gitgutter | gitsigns.nvim |
|---|---|---|
| Sign column markers | ✓ | ✓ (customizable) |
| Hunk navigation | `]c` / `[c` | `]h` / `[h` |
| Stage hunk | -- | `<Leader>hs` |
| Reset hunk | -- | `<Leader>hr` |
| Preview hunk | -- | `<Leader>hp` |
| Inline blame | -- | `<Leader>gb` (toggle) |
| Hunk text object | -- | `ih` (select hunk in visual/operator) |
| Performance | Good | Better (Lua, async) |

### What gitsigns adds over gitgutter

- **Hunk staging/unstaging** directly from the editor (`<Leader>hs`)
- **Inline blame** showing who last changed the line (`<Leader>gb`)
- **Hunk text object** (`ih`) -- `dih` to delete a hunk, `vih` to select it
- **Preview hunks** in a floating window (`<Leader>hp`)
- **Undo stage** (`<Leader>hu`) -- unstage the last staged hunk

## diffview.nvim (New)

No old equivalent. This provides:

- Side-by-side diff view of all changed files
- File history browser (like `git log --follow` but visual)
- Merge conflict resolution interface
- Integration with fugitive

| Binding | Action |
|---|---|
| `<Leader>gd` | Open diff view (all changes) |
| `<Leader>gh` | File history for current file |
| `<Leader>gH` | Full branch history |

Inside diffview, use `]x` / `[x` to navigate conflicts, and choose ours/theirs/both.

## Fugitive Keybindings Reference

These come from fugitive itself (no config needed):

| Binding | Action |
|---|---|
| `:Git` | Full-screen git status (stage with `s`, unstage with `u`) |
| `:Git blame` | Side-by-side blame |
| `:Git diff` | Diff in splits |
| `:Git log` | Log browser |
| `:GBrowse` | Open current file on GitHub (vim-rhubarb) |

## Plugins to Remove

| Plugin | Status |
|--------|--------|
| `airblade/vim-gitgutter` | Replaced by gitsigns.nvim |
| `tpope/vim-git` | Treesitter handles git filetype syntax (gitcommit, gitrebase parsers) |

## Git Keybinding Summary

All git-related bindings in one place:

| Binding | Action | Plugin |
|---|---|---|
| `]h` / `[h` | Next/prev hunk | gitsigns |
| `<Leader>hs` | Stage hunk | gitsigns |
| `<Leader>hr` | Reset hunk | gitsigns |
| `<Leader>hS` | Stage entire buffer | gitsigns |
| `<Leader>hu` | Undo last stage | gitsigns |
| `<Leader>hp` | Preview hunk | gitsigns |
| `<Leader>gb` | Toggle inline blame | gitsigns |
| `<Leader>hd` | Diff this file | gitsigns |
| `<Leader>gd` | Open diff view | diffview |
| `<Leader>gh` | File history | diffview |
| `:Git` | Git status | fugitive |
| `:GBrowse` | Open on GitHub | vim-rhubarb |

## Checklist

- [ ] Add git plugins to `lua/plugins/git.lua`
- [ ] Run `:Lazy sync`
- [ ] Test: gutter signs appear when modifying a tracked file
- [ ] Test: `]h` / `[h` navigate between hunks
- [ ] Test: `<Leader>hp` previews the hunk in a float
- [ ] Test: `<Leader>gb` toggles inline blame
- [ ] Test: `<Leader>hs` stages a hunk (verify with `:Git`)
- [ ] Test: `<Leader>gd` opens diffview
- [ ] Test: `:GBrowse` opens the file on GitHub
- [ ] Verify vim-fugitive still works as expected
