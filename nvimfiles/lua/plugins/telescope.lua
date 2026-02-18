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
            ignore_current_buffer = true,
          },
        },
      })

      telescope.load_extension("fzf")
    end,
  },
}
