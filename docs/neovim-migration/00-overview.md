# 00 -- Overview and Strategy

## Current State

Your `vimfiles/` directory is a mature Vim config built over many years:

- **Plugin manager:** vim-plug (`call plug#begin()`)
- **~60 plugins** across navigation, git, language support, completion, UI
- **Colorscheme:** jellybeans+ (custom variant)
- **Leader:** Space
- **Config structure:** `.vimrc` sources 6 config files from `config/`
  - `plugins.vim` (283 lines of plugin settings)
  - `settings.vim` (107 lines)
  - `mappings.vim` (196 lines)
  - `autocommands.vim` (67 lines)
  - `commands.vim` (43 lines)
  - `statusline.vim` (31 lines)
- **ftplugin:** ruby, go, javascript, coffee, php, processing
- **Snippets:** custom ruby/rspec snippets in `_snippets/`
- **Neovim shim:** `install.sh` symlinks `vimfiles/` to `~/.config/nvim`, `.vimrc` has `if has('nvim')` blocks for treesitter, lspconfig, nvim-cmp

There's also an early-stage `nvimfiles/` directory with:
- lazy.nvim bootstrap
- kanagawa colorscheme
- Basic treesitter + textobjects
- `options.lua` with 4-space tabs, `scrolloff=999`, `ignorecase`

**What works today:** Neovim launches with the vimfiles shim. Treesitter highlighting works. nvim-cmp and lspconfig are installed but minimally configured (no LSP servers auto-installed, no mason).

**What's missing:** LSP server management, proper completion config, Lua-native navigation (telescope, neo-tree), modern git integration (gitsigns), formatting, linting, and the entire keymap/autocommand config is still VimScript running through the shim.

## Decision Log

| Decision | Choice | Rationale |
|---|---|---|
| Vim compatibility | **Neovim-only** | Freeze `vimfiles/` as archive, commit fully to `nvimfiles/` |
| Default indent | **4-space** | Ruby stays 2-space via ftplugin |
| Scroll behavior | **scrolloff=999** | Cursor stays centered; revert to 3 or 0 if disorienting |
| Fuzzy finder | **telescope.nvim** | Replaces ctrlp + fzf.vim + ack.vim + bufexplorer |
| File browser | **neo-tree.nvim** | Replaces NERDTree |
| Colorscheme | **jellybeans.nvim** (`wtfox/jellybeans.nvim`) | Familiar look, treesitter-aware |
| Snippets | **LuaSnip + friendly-snippets** | Community base, port custom ruby/rspec on top |
| "Tech words" highlight | **Keep** | Port to Lua |
| CoffeeScript/PHP/Processing ftplugins | **Drop** | No longer needed |

## Migration Strategy

**Build on `nvimfiles/`, port incrementally, working editor at every step.**

The approach:
1. Never break the editor. Each chapter ends with a checklist to verify things work.
2. Port config conceptually, not line-by-line. Use Lua idioms, not VimScript transliterations.
3. Replace plugins where Lua-native alternatives exist. Keep battle-tested tpope plugins.
4. Add new capabilities (LSP, mason, formatting, inlay hints) that weren't possible before.

## Phase Summary

| Phase | Chapter | What You Get |
|---|---|---|
| Foundation | [01-foundations](01-foundations.md) | Directory structure, `init.lua`, options, symlink |
| Core Editing | [02-core-editing](02-core-editing.md) | Keymaps, autocommands, user commands |
| Navigation | [03-navigation](03-navigation.md) | Telescope, neo-tree, flash.nvim |
| LSP | [04-lsp-and-completion](04-lsp-and-completion.md) | Mason, language servers, nvim-cmp, formatting |
| Git | [05-git](05-git.md) | Gitsigns, diffview, keep fugitive |
| UI | [06-ui](06-ui.md) | Lualine, jellybeans.nvim, which-key, indent guides |
| Languages | [07-languages-and-treesitter](07-languages-and-treesitter.md) | Treesitter deep-dive, textobjects, ftplugins, snippets |
| New Powers | [08-things-you-didnt-know](08-things-you-didnt-know.md) | Inlay hints, terminal, lazy-loading, sessions |
| Cleanup | [09-cleanup](09-cleanup.md) | Install script, env, dead code, freeze vimfiles |

**Dependencies:** Chapters 01 and 02 must be done first. After that, 03-08 can be done in any order (though the listed order is recommended). Chapter 09 is last.

## Reference

- [Appendix: Plugin Migration Map](appendix-plugin-map.md) -- every plugin mapped to keep/replace/remove
- [Appendix: VimScript to Lua Primer](appendix-lua-primer.md) -- translation cheat sheet

## Checklist

- [ ] Read this overview
- [ ] Skim the appendices for orientation
- [ ] Start with [01-foundations](01-foundations.md)
