return {
  -- Surround text objects
  { "tpope/vim-surround" },

  -- Make . repeat work with plugin mappings
  { "tpope/vim-repeat" },

  -- Alignment
  { "junegunn/vim-easy-align" },

  -- Indent text object
  { "michaeljsmith/vim-indent-object" },

  -- Unimpaired: ]q, [q, ]b, [b, etc.
  { "tpope/vim-unimpaired" },

  -- Abolish: :Subvert, coercion (crs, crc)
  { "tpope/vim-abolish" },

  -- HTML/template tag helpers
  { "tpope/vim-ragtag" },

  -- Readline keybindings in insert/cmdline
  { "tpope/vim-rsi" },

  -- tmux/neovim split navigation
  { "christoomey/vim-tmux-navigator" },

  -- Async :Make, :Dispatch
  { "tpope/vim-dispatch" },

  -- Alternate file navigation (:A, :Esource, :Etest, etc.)
  {
    "tpope/vim-projectionist",
    lazy = false,
    init = function()
      vim.g.projectionist_heuristics = {
        -- Ruby projects (non-Rails; vim-rails handles standard Rails paths)
        ["Gemfile&!config/environment.rb"] = {
          ["lib/*.rb"] = {
            alternate = "spec/{}_spec.rb",
            type = "source",
          },
          ["spec/*_spec.rb"] = {
            alternate = "lib/{}.rb",
            type = "spec",
            dispatch = "bundle exec rspec {file}",
          },
          ["test/*_test.rb"] = {
            alternate = "lib/{}.rb",
            type = "test",
            dispatch = "bundle exec ruby -Itest {file}",
          },
        },
        -- Rails extensions (services, policies, etc. that vim-rails doesn't cover)
        ["config/environment.rb"] = {
          ["app/services/*.rb"] = {
            alternate = "spec/services/{}_spec.rb",
            type = "service",
          },
          ["spec/services/*_spec.rb"] = {
            alternate = "app/services/{}.rb",
            type = "spec",
            dispatch = "bundle exec rspec {file}",
          },
          ["app/policies/*.rb"] = {
            alternate = "spec/policies/{}_spec.rb",
            type = "policy",
          },
          ["spec/policies/*_spec.rb"] = {
            alternate = "app/policies/{}.rb",
            type = "spec",
            dispatch = "bundle exec rspec {file}",
          },
          ["app/components/*.rb"] = {
            alternate = "spec/components/{}_spec.rb",
            type = "component",
          },
          ["spec/components/*_spec.rb"] = {
            alternate = "app/components/{}.rb",
            type = "spec",
            dispatch = "bundle exec rspec {file}",
          },
          ["app/wizards/*.rb"] = {
            alternate = "spec/wizards/{}_spec.rb",
            type = "wizard",
          },
          ["spec/wizards/*_spec.rb"] = {
            alternate = "app/wizards/{}.rb",
            type = "spec",
            dispatch = "bundle exec rspec {file}",
          },
          ["app/lib/*.rb"] = {
            alternate = "spec/lib/{}_spec.rb",
            type = "lib",
          },
          ["spec/lib/*_spec.rb"] = {
            alternate = "app/lib/{}.rb",
            type = "spec",
            dispatch = "bundle exec rspec {file}",
          },
        },
        -- TypeScript projects
        ["tsconfig.json"] = {
          ["src/*.ts"] = {
            alternate = { "src/{}.test.ts", "src/{}.spec.ts" },
            type = "source",
          },
          ["src/*.test.ts"] = {
            alternate = "src/{}.ts",
            type = "test",
            dispatch = "npx vitest run {file}",
          },
          ["src/*.spec.ts"] = {
            alternate = "src/{}.ts",
            type = "test",
            dispatch = "npx vitest run {file}",
          },
          ["src/*.tsx"] = {
            alternate = { "src/{}.test.tsx", "src/{}.spec.tsx" },
            type = "source",
          },
          ["src/*.test.tsx"] = {
            alternate = "src/{}.tsx",
            type = "test",
            dispatch = "npx vitest run {file}",
          },
          ["src/*.spec.tsx"] = {
            alternate = "src/{}.tsx",
            type = "test",
            dispatch = "npx vitest run {file}",
          },
        },
        -- JavaScript projects (no tsconfig)
        ["package.json&!tsconfig.json"] = {
          ["src/*.js"] = {
            alternate = { "src/{}.test.js", "src/{}.spec.js" },
            type = "source",
          },
          ["src/*.test.js"] = {
            alternate = "src/{}.js",
            type = "test",
            dispatch = "npx jest {file}",
          },
          ["src/*.spec.js"] = {
            alternate = "src/{}.js",
            type = "test",
            dispatch = "npx jest {file}",
          },
        },
      }
    end,
  },

  -- Ruby
  { "vim-ruby/vim-ruby", ft = "ruby" },
  { "tpope/vim-rails", lazy = false },
  { "tpope/vim-bundler", lazy = false },

  -- HTML expansion
  { "mattn/emmet-vim", ft = { "html", "eruby", "javascript", "typescript", "tsx" } },

  -- CSV
  { "chrisbra/csv.vim", ft = "csv" },

  -- Database client
  {
    "tpope/vim-dadbod",
    cmd = "DB",
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod" },
    cmd = { "DBUI", "DBUIToggle" },
    keys = {
      { "<Leader>db", "<cmd>DBUIToggle<CR>", desc = "Toggle database UI" },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = { "tpope/vim-dadbod" },
    ft = { "sql", "mysql", "plsql" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          require("cmp").setup.buffer({
            sources = {
              { name = "vim-dadbod-completion" },
              { name = "buffer" },
            },
          })
        end,
      })
    end,
  },
}
