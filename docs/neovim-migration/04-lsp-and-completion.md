# 04 -- LSP, Mason, Completion, Formatting

This is the biggest missing piece in your current config. The old setup uses syntastic (synchronous, blocks the editor). The new setup uses neovim's built-in LSP client with mason for server management.

## mason.nvim + mason-lspconfig.nvim

Mason auto-installs language servers so you don't need to `brew install` or `npm install -g` them manually.

### Plugin spec: `lua/plugins/lsp.lua`

> **Neovim 0.11+ note:** The old `require('lspconfig')[server].setup()` API is deprecated.
> Use `vim.lsp.config()` and `vim.lsp.enable()` instead (see `:help lspconfig-nvim-0.11`).

```lua
return {
  -- Mason: auto-install language servers
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },

  -- Bridge mason + lspconfig (for ensure_installed)
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",          -- Lua
          "ruby_lsp",        -- Ruby (Shopify's ruby-lsp)
          "ts_ls",           -- TypeScript/JavaScript
          "gopls",           -- Go
          "rust_analyzer",   -- Rust
          "terraformls",     -- Terraform
          "bashls",          -- Bash
          "jsonls",          -- JSON
          "yamlls",          -- YAML
          "dockerls",        -- Dockerfile
          "ruff",            -- Python (linting + formatting)
        },
        automatic_installation = true,
      })
    end,
  },

  -- LSP config (neovim 0.11+ native vim.lsp.config API)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Keymaps (only active when LSP attaches)
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "References")
          map("gI", vim.lsp.buf.implementation, "Go to implementation")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gy", vim.lsp.buf.type_definition, "Type definition")
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("<Leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<Leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<Leader>e", vim.diagnostic.open_float, "Show diagnostic")
          map("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")

          -- Inlay hints toggle (neovim 0.10+)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.supports_method("textDocument/inlayHint") then
            map("<Leader>ih", function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
            end, "Toggle inlay hints")
          end
        end,
      })

      -- Default capabilities for all servers
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- lua_ls needs extra config for neovim Lua development
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
            telemetry = { enable = false },
          },
        },
      })

      -- Enable all servers
      vim.lsp.enable({
        "lua_ls", "ruby_lsp", "ts_ls", "gopls", "rust_analyzer",
        "terraformls", "bashls", "jsonls", "yamlls", "dockerls", "ruff",
      })

      -- Diagnostic display configuration
      vim.diagnostic.config({
        virtual_text = { spacing = 4, prefix = "●" },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✗",
            [vim.diagnostic.severity.WARN] = "⚠",
            [vim.diagnostic.severity.HINT] = "⚑",
            [vim.diagnostic.severity.INFO] = "ℹ",
          },
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = true,
        },
      })
    end,
  },
}
```

### LSP Keybinding Reference

| Binding | Action | Notes |
|---|---|---|
| `gd` | Go to definition | Jump to where symbol is defined |
| `gr` | References | Find all usages |
| `gI` | Implementation | Go to interface implementation |
| `gD` | Declaration | Go to declaration (if different from definition) |
| `gy` | Type definition | Jump to the type of the symbol |
| `K` | Hover docs | Show documentation popup |
| `<Leader>rn` | Rename | Rename symbol across project |
| `<Leader>ca` | Code action | Quick fixes, refactors |
| `<Leader>e` | Diagnostic float | Show full diagnostic message |
| `[d` / `]d` | Prev/next diagnostic | Navigate between errors/warnings |
| `<Leader>ih` | Toggle inlay hints | Only shown if server supports it |

## nvim-cmp (Completion)

The existing config has nvim-cmp installed but barely configured. Here's a proper setup.

### Plugin spec: `lua/plugins/completion.lua`

```lua
return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      -- Snippets
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        dependencies = {
          "rafamadriz/friendly-snippets",  -- community snippet collection
        },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
          -- Load custom snippets (ported from vimfiles/_snippets/)
          require("luasnip.loaders.from_snipmate").lazy_load({ paths = { "./snippets" } })
        end,
      },
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          -- Tab for snippet jumping and completion
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        -- Source ordering matters: first match wins for priority
        sources = cmp.config.sources({
          { name = "nvim_lsp" },    -- LSP completions (highest priority)
          { name = "luasnip" },     -- Snippet completions
        }, {
          { name = "buffer" },      -- Words from current buffer
          { name = "path" },        -- File paths
        }),
        -- Ghost text preview (neovim 0.10+)
        experimental = {
          ghost_text = true,
        },
      })

      -- Cmdline completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      -- Search completion
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },
}
```

### Completion Keybinding Reference

| Binding | Action |
|---|---|
| `<Tab>` / `<S-Tab>` | Navigate completion menu / jump snippet placeholders |
| `<C-n>` / `<C-p>` | Next/previous completion item |
| `<CR>` | Confirm selection |
| `<C-Space>` | Trigger completion manually |
| `<C-e>` | Abort completion |
| `<C-b>` / `<C-f>` | Scroll documentation |

### Note on `<C-f>` conflict

`<C-f>` is mapped to telescope `git_files` in normal mode and to `scroll_docs` in nvim-cmp's insert mode. This is fine because they're in different modes, but if it bothers you, remap one of them.

## conform.nvim (Formatting)

Async formatting on save, replacing ad-hoc formatting approaches.

### Plugin spec: `lua/plugins/formatting.lua`

```lua
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
        ["_"] = { "trim_whitespace" },  -- all filetypes
      },
      format_on_save = {
        timeout_ms = 3000,
        lsp_fallback = true,
      },
    },
  },
}
```

## nvim-lint (Linting)

For linters that don't have LSP equivalents.

### Plugin spec: `lua/plugins/linting.lua`

```lua
return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        -- Add non-LSP linters here as needed
        -- Most linting is handled by LSP servers (ruby-lsp, ruff, etc.)
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("Linting", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
```

## What This Replaces

| Old Plugin | Problem | New Solution |
|---|---|---|
| syntastic | **Synchronous** -- blocks editor while linting | LSP (async) + nvim-lint (async) |
| vim-vsnip + cmp-vsnip | Works but less community support | LuaSnip + friendly-snippets |
| (no formatter) | Manual formatting only | conform.nvim (auto-format on save) |
| (no LSP management) | Had to install servers manually | mason.nvim (auto-install) |

## Custom Snippets

Your `vimfiles/_snippets/ruby.snippets` has valuable rspec snippets (describe, context, it, expect, let, etc.). To port them:

1. Create `nvimfiles/snippets/` directory
2. Convert to snipmate format (they're already close) or VSCode JSON format
3. Load in LuaSnip config:

```lua
-- snipmate format
require("luasnip.loaders.from_snipmate").lazy_load({ paths = "./snippets" })

-- or VSCode JSON format
require("luasnip.loaders.from_vscode").lazy_load({ paths = "./snippets" })
```

This is covered in detail in [07-languages-and-treesitter](07-languages-and-treesitter.md).

## Checklist

- [ ] Create `lua/plugins/lsp.lua`
- [ ] Create `lua/plugins/completion.lua`
- [ ] Create `lua/plugins/formatting.lua`
- [ ] Create `lua/plugins/linting.lua`
- [ ] Run `:Lazy sync` to install mason, lspconfig, conform, etc.
- [ ] Run `:Mason` to verify language servers install
- [ ] Test: open a Lua file, verify lua_ls attaches (`:LspInfo`)
- [ ] Test: open a Ruby file, verify ruby_lsp attaches
- [ ] Test: `gd` jumps to definition
- [ ] Test: `K` shows hover documentation
- [ ] Test: `<Leader>rn` renames a symbol
- [ ] Test: completion popup appears when typing
- [ ] Test: Tab navigates the completion menu
- [ ] Test: formatting runs on save (`:ConformInfo` to check)
- [ ] Test: diagnostics appear in the gutter with ✗ and ⚠ signs
