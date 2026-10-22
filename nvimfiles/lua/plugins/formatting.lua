return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<Leader>bf",
        function() require("conform").format({ async = true, lsp_fallback = true }) end,
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        ruby = { "rubocop" },
        terraform = { "terraform_fmt" },
        gdscript = { "gdstyle" },
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        -- gdstyle (github.com/atelico/gdstyle) only formats in place, no stdin.
        -- Installed from its GitHub release into ~/.local/bin (no brew formula).
        gdstyle = {
          command = "gdstyle",
          args = { "fmt", "--no-color", "$FILENAME" },
          stdin = false,
          cwd = function(self, ctx)
            return require("conform.util").root_file({ "gdstyle.toml", ".gdstyle.toml", "project.godot" })(self, ctx)
          end,
        },
      },
      format_on_save = {
        timeout_ms = 3000,
        lsp_fallback = true,
      },
    },
  },
}
