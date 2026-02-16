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
            visible = true,
            hide_dotfiles = false,
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
          mappings = {
            ["s"] = "none",           -- free up for flash.nvim
            ["S"] = "none",           -- free up for flash.nvim
            ["<C-v>"] = "open_vsplit",
            ["<C-x>"] = "open_split",
          },
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
