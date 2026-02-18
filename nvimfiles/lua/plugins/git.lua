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
      current_line_blame = false,
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
