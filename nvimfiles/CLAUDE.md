# Neovim Config

## Key Conventions

- Plugins are managed by lazy.nvim; adding a plugin means adding to the appropriate `lua/plugins/*.lua` file
- Per-language settings (indent, dispatch commands) go in `after/ftplugin/{lang}.lua`
- Projectionist heuristics are global in `editing.lua`; per-project overrides go in `.projections.json` at project root
- Project-local neovim config uses `.nvim.lua` at project root (`exrc` is enabled)
- Reference docs live in `docs/neovim-reference/` -- keep them in sync when changing configs or plugins

## Known Issues

- `<Leader>hs` is mapped twice: toggle hlsearch (keymaps.lua) and stage hunk (gitsigns, buffer-local). Gitsigns wins in git-tracked buffers. Intentional.
- `ai`/`ii` conflict: treesitter textobjects (`@conditional`) override vim-indent-object. Use `aI`/`iI` (capital I) for strict indent matching.
- which-key group label `<Leader>s` says "treesitter selection" but is actually "Source config" -- stale label in ui.lua.
