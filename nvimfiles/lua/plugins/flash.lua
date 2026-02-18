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
          enabled = false,
        },
        char = {
          enabled = true,
        },
      },
    },
  },
}
