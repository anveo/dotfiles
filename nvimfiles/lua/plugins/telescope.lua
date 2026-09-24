return {
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
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
      { "<C-F>", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<C-G>", "<cmd>Telescope git_files<CR>", desc = "Git files" },
      { "<Leader>f", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<Leader>F", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      { "<C-B>", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<Leader><Tab>", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
      { "<Leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<Leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<Leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<Leader>fg", "<cmd>Telescope git_status<CR>", desc = "Git status" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- The stock actions.delete_buffer lets nvim_buf_delete close every window
      -- showing the buffer. If that leaves only neo-tree, its
      -- close_if_last_window quits Neovim. Point those windows at the most
      -- recently used other buffer first so the layout survives.
      local function delete_buffer_keep_windows(prompt_bufnr)
        local picker = action_state.get_current_picker(prompt_bufnr)
        picker:delete_selection(function(selection)
          local bufnr = selection.bufnr
          if vim.bo[bufnr].modified then
            vim.notify("Unsaved changes, not deleting: " .. vim.api.nvim_buf_get_name(bufnr), vim.log.levels.WARN)
            return false
          end

          local replacement
          local last_used = -1
          for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
            if info.bufnr ~= bufnr and info.lastused > last_used then
              replacement, last_used = info.bufnr, info.lastused
            end
          end
          replacement = replacement or vim.api.nvim_create_buf(true, false)

          for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
            vim.api.nvim_win_set_buf(win, replacement)
          end
          if picker.original_bufnr == bufnr then
            picker.original_bufnr = replacement
          end

          local force = vim.bo[bufnr].buftype == "terminal"
          return pcall(vim.api.nvim_buf_delete, bufnr, { force = force })
        end)
      end

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
              ["<Esc>"] = actions.close,
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
            -- BufExplorer-style: open in normal mode (j/k, d, q); `i` to fuzzy
            -- filter. <C-d> deletes from insert mode, overriding preview
            -- scroll-down in this picker only.
            initial_mode = "normal",
            -- attach_mappings, not `mappings`: per-picker `mappings` drop keymap
            -- opts, and `d` needs nowait so it doesn't pause for global
            -- d-prefixed maps (surround's ds, marks' dm*).
            attach_mappings = function(_, map)
              map("i", "<C-d>", delete_buffer_keep_windows)
              map("n", "d", delete_buffer_keep_windows, { nowait = true })
              map("n", "q", actions.close)
              return true
            end,
          },
        },
      })

      telescope.load_extension("fzf")
    end,
  },
}
