# Dotfiles Project

## Neovim Config Structure

```
nvimfiles/
  init.lua                  -- Entry point: loads options, keymaps, autocmds, commands, lazy
  lua/
    options.lua             -- vim.opt settings (leader=Space, exrc enabled)
    keymaps.lua             -- Global keymaps
    autocmds.lua            -- Autocommands (restore cursor, filetype overrides, etc.)
    commands.lua            -- Custom :commands (:Strip, :NotRocket, :F, :SudoWrite)
    config/lazy.lua         -- lazy.nvim bootstrap
    plugins/                -- One file per category, each returns a lazy.nvim spec table
      completion.lua        -- nvim-cmp, LuaSnip, sources
      editing.lua           -- surround, align, abolish, projectionist, rails, dadbod, etc.
      flash.lua             -- flash.nvim motion
      formatting.lua        -- conform.nvim (format on save)
      git.lua               -- fugitive, gitsigns, diffview
      linting.lua           -- nvim-lint
      lsp.lua               -- lspconfig, mason
      neo-tree.lua          -- File explorer
      telescope.lua         -- Fuzzy finder
      treesitter.lua        -- Treesitter, textobjects, context
      ui.lua                -- Colorscheme, lualine, which-key, indent guides, etc.
  after/ftplugin/           -- Per-language overrides (indent, dispatch defaults)
  snippets/                 -- Custom snipmate-format snippets (all.snippets, ruby.snippets)
```

## Key Conventions

- Plugins are managed by lazy.nvim; adding a plugin means adding to the appropriate `lua/plugins/*.lua` file
- Per-language settings (indent, dispatch commands) go in `after/ftplugin/{lang}.lua`
- Projectionist heuristics are global in `editing.lua`; per-project overrides go in `.projections.json` at project root
- Project-local neovim config uses `.nvim.lua` at project root (`exrc` is enabled)
- Reference docs live in `docs/neovim-reference/` and `docs/tmux-reference/` -- keep them in sync when changing configs or plugins

## Known Issues

- `<Leader>hs` is mapped twice: toggle hlsearch (keymaps.lua) and stage hunk (gitsigns, buffer-local). Gitsigns wins in git-tracked buffers. Intentional.
- `ai`/`ii` conflict: treesitter textobjects (`@conditional`) override vim-indent-object. Use `aI`/`iI` (capital I) for strict indent matching.
- which-key group label `<Leader>s` says "treesitter selection" but is actually "Source config" -- stale label in ui.lua.

## Terminal & Multiplexer

- **Ghostty** is the terminal emulator; config lives at `extras/ghostty/config` (symlinked to `~/.config/ghostty/config`)
  - Custom themes in `extras/ghostty/themes/`
  - `mouse-shift-capture = false` — hold Shift to bypass tmux mouse capture for native text selection
- **tmux** config is `.tmux.conf` at repo root
  - Prefix: `C-Space`
  - Mouse enabled (`mouse on`), focus events enabled
  - vim-tmux-navigator for seamless pane navigation with `C-h/j/k/l`
  - vi copy mode with pbcopy integration
  - TPM plugins: tpm, tmux-continuum, tmux-yank

## Other Dotfiles

- `Brewfile` -- Homebrew packages (includes tree-sitter and tree-sitter-cli for treesitter parser compilation)
- `bin/install.sh` -- Symlink setup script (`make install`)
- Monicur project (`~/code/monicur/monicur`) has a `.nvim.lua` for dadbod DATABASE_URL integration
