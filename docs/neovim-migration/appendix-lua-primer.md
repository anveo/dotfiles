# Appendix: VimScript to Lua Reference

Quick-reference for translating your existing VimScript config into Lua.

## Options

```vim
" VimScript
set shiftwidth=4
set noexpandtab
set wildignore+=*.o,*.out
```

```lua
-- Lua
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.wildignore:append({ "*.o", "*.out" })
```

| VimScript | Lua |
|---|---|
| `set X` | `vim.opt.X = true` |
| `set noX` | `vim.opt.X = false` |
| `set X=value` | `vim.opt.X = value` |
| `set X+=value` | `vim.opt.X:append(value)` |
| `set X-=value` | `vim.opt.X:remove(value)` |
| `setlocal X` | `vim.opt_local.X = true` |

## Variables

```vim
" VimScript
let g:mapleader = " "
let b:surround_{char2nr('#')} = "#{\r}"
let &t_SI = "\<Esc>..."
```

```lua
-- Lua
vim.g.mapleader = " "
vim.b["surround_" .. string.byte("#")] = "#{\\r}"
-- Terminal codes: use vim.cmd() or just skip (neovim handles cursors natively)
```

| VimScript | Lua |
|---|---|
| `let g:X = val` | `vim.g.X = val` |
| `let b:X = val` | `vim.b.X = val` |
| `let w:X = val` | `vim.w.X = val` |
| `let &option = val` | `vim.o.option = val` |

## Keymaps

```vim
" VimScript
nnoremap <Leader>w :w<CR>
nmap <leader>d :NERDTreeToggle<CR>
imap jj <Esc>
vnoremap > >gv
map ; :
```

```lua
-- Lua
vim.keymap.set("n", "<Leader>w", "<cmd>w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<Leader>d", "<cmd>NERDTreeToggle<CR>")  -- remap=true if needed
vim.keymap.set("i", "jj", "<Esc>")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set({ "n", "v", "o" }, ";", ":")  -- map applies to n, v, o
```

| VimScript | Lua `vim.keymap.set` mode |
|---|---|
| `nmap` / `nnoremap` | `"n"` |
| `imap` / `inoremap` | `"i"` |
| `vmap` / `vnoremap` | `"v"` |
| `xmap` / `xnoremap` | `"x"` |
| `omap` / `onoremap` | `"o"` |
| `map` / `noremap` | `{ "n", "v", "o" }` |
| `map!` | `{ "i", "c" }` |

**Key differences:**
- `vim.keymap.set` is `noremap` by default (non-recursive)
- Pass `{ remap = true }` for recursive mappings (old `nmap` behavior)
- `<cmd>...<CR>` is preferred over `:...<CR>` (doesn't change mode)
- Use `{ buffer = true }` for buffer-local mappings (replaces `<buffer>`)
- Use `{ silent = true }` for silent mappings
- Use `{ desc = "..." }` so which-key can display the mapping

## Autocommands

```vim
" VimScript
autocmd FileType make setlocal noexpandtab
autocmd BufRead,BufNewFile {Gemfile,Rakefile} set ft=ruby
augroup MyGroup
  autocmd!
  autocmd BufWritePost * Neomake
augroup END
```

```lua
-- Lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "Gemfile", "Rakefile" },
  callback = function()
    vim.bo.filetype = "ruby"
  end,
})

local group = vim.api.nvim_create_augroup("MyGroup", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  callback = function()
    -- ...
  end,
})
```

## User Commands

```vim
" VimScript
command! -nargs=1 -complete=filetype F set filetype=<args>
command! Strip let _s=@/<Bar>:%s/\s\+$//e<Bar>:let @/=_s<Bar>:nohl
command! -bar -range=% NotRocket execute '<line1>,<line2>s/:\(\w\+\)\s*=>/\1:/e' . (&gdefault ? '' : 'g')
```

```lua
-- Lua
vim.api.nvim_create_user_command("F", function(opts)
  vim.bo.filetype = opts.args
end, { nargs = 1, complete = "filetype" })

vim.api.nvim_create_user_command("Strip", function()
  local save = vim.fn.getreg("/")
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.setreg("/", save)
  vim.cmd("nohl")
end, {})

vim.api.nvim_create_user_command("NotRocket", function(opts)
  local cmd = opts.line1 .. "," .. opts.line2 .. [[s/:\(\w\+\)\s*=>/\1:/ge]]
  vim.cmd(cmd)
end, { range = "%" })
```

## Functions

```vim
" VimScript
function! NumberToggle()
  if(&relativenumber == 1)
    set norelativenumber
  else
    set relativenumber
  endif
endfunc
```

```lua
-- Lua
local function number_toggle()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end
```

## Sourcing / Requiring

```vim
" VimScript
source ~/.vim/config/settings.vim
runtime ftplugin/ruby.vim
```

```lua
-- Lua
require("config.settings")    -- loads lua/config/settings.lua
-- No equivalent of runtime needed; lazy.nvim handles plugin loading
```

**Module resolution:** `require("foo.bar")` looks for `lua/foo/bar.lua` or `lua/foo/bar/init.lua` relative to any directory in `runtimepath`.

## The `vim.cmd()` Escape Hatch

When in doubt, wrap any VimScript in `vim.cmd()`:

```lua
vim.cmd("colorscheme jellybeans")
vim.cmd("highlight ColorColumn ctermbg=234 guibg=#261e1e")
vim.cmd([[
  augroup legacy
    autocmd!
    autocmd FileType help nnoremap <buffer> q <cmd>q<CR>
  augroup END
]])
```

This is a legitimate long-term strategy for things that are awkward in Lua (like complex highlight definitions or regex-heavy substitutions). No need to port everything on day one.

## Common Gotchas

1. **Booleans:** Lua uses `true`/`false`, not `1`/`0`
2. **String concatenation:** `..` not `+` or `.`
3. **Not-equal:** `~=` not `!=`
4. **Nil vs false:** Both are falsy, but they're different values
5. **Tables are 1-indexed** (but most vim APIs use 0-indexed, confusingly)
6. **No `+=` operator:** Use `x = x + 1` or `vim.opt.X:append()`
7. **Single vs double quotes:** Both work identically in Lua (unlike VimScript where `"` interprets escapes)

## Checklist

- [ ] Read this page once for orientation
- [ ] Bookmark it -- you'll reference it throughout the migration
- [ ] Try converting one simple mapping by hand to build muscle memory
