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

  -- Textobjects
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local ts_select = require("nvim-treesitter-textobjects.select")
      local ts_move = require("nvim-treesitter-textobjects.move")
      local ts_swap = require("nvim-treesitter-textobjects.swap")

      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      -- Select textobjects
      local select_maps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
        ["ab"] = "@block.outer",
        ["ib"] = "@block.inner",
      }
      for key, query in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          ts_select.select_textobject(query, "textobjects")
        end, { desc = query })
      end

      -- Move: next start
      for key, query in pairs({
        ["]f"] = "@function.outer",
        ["]c"] = "@class.outer",
        ["]a"] = "@parameter.outer",
      }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          ts_move.goto_next_start(query, "textobjects")
        end, { desc = "Next " .. query })
      end

      -- Move: next end
      for key, query in pairs({
        ["]F"] = "@function.outer",
        ["]C"] = "@class.outer",
      }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          ts_move.goto_next_end(query, "textobjects")
        end, { desc = "Next " .. query .. " end" })
      end

      -- Move: previous start
      for key, query in pairs({
        ["[f"] = "@function.outer",
        ["[c"] = "@class.outer",
        ["[a"] = "@parameter.outer",
      }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          ts_move.goto_previous_start(query, "textobjects")
        end, { desc = "Prev " .. query })
      end

      -- Move: previous end
      for key, query in pairs({
        ["[F"] = "@function.outer",
        ["[C"] = "@class.outer",
      }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          ts_move.goto_previous_end(query, "textobjects")
        end, { desc = "Prev " .. query .. " end" })
      end

      -- Swap parameters
      vim.keymap.set("n", "<Leader>a", function()
        ts_swap.swap_next("@parameter.inner")
      end, { desc = "Swap parameter with next" })
      vim.keymap.set("n", "<Leader>A", function()
        ts_swap.swap_previous("@parameter.inner")
      end, { desc = "Swap parameter with previous" })
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
  -- Using vim-endwise since nvim-treesitter-endwise is incompatible with new treesitter API
  { "tpope/vim-endwise" },
}
