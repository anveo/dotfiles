return {
  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "jellybeans",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- Colorscheme: jellybeans.nvim
  {
    "wtfox/jellybeans.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("jellybeans").setup({})
      vim.cmd.colorscheme("jellybeans")

      vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#261e1e" })
      vim.api.nvim_set_hl(0, "LineProximity", { bg = "#212121" })
      vim.api.nvim_set_hl(0, "LineOverflow", { bg = "#902020" })
      vim.api.nvim_set_hl(0, "TechWordsToAvoid", { bg = "#902020", fg = "#ffffff" })
      vim.api.nvim_set_hl(0, "SpecialKey", { fg = "#ffffff", bg = "#902020" })
      vim.api.nvim_set_hl(0, "NonText", { fg = "#222222" })
    end,
  },

  -- Which-key: keybinding discovery popup
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<Leader>f", group = "find/files" },
        { "<Leader>g", group = "git" },
        { "<Leader>h", group = "hunks" },
        { "<Leader>t", group = "tabs" },
        { "<Leader>s", group = "treesitter selection" },
      },
    },
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      indent = {
        char = "│",
      },
      scope = {
        enabled = true,
      },
      exclude = {
        filetypes = { "help", "neo-tree", "lazy", "mason" },
      },
    },
  },

  -- Better UI for vim.ui.select and vim.ui.input
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- File type icons
  {
    "nvim-tree/nvim-web-devicons",
    lazy = true,
  },

  -- Color previews in code
  {
    "norcalli/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("colorizer").setup({
        "*",
      }, {
        css = true,
        css_fn = true,
      })
    end,
  },

  -- TODO/FIXME/HACK highlighting and searching
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous TODO" },
      { "<Leader>ft", "<cmd>TodoTelescope<CR>", desc = "Search TODOs" },
    },
    opts = {},
  },

  -- Toggle terminal
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
      direction = "horizontal",
      shade_terminals = true,
      float_opts = {
        border = "curved",
      },
    },
  },
}
