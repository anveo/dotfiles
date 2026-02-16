# 02 -- Keymaps, Commands, Autocommands

## `lua/keymaps.lua`

Port all mappings from `vimfiles/config/mappings.vim` (196 lines) and `vimfiles/config/plugins.vim` (plugin-specific bindings). Plugin-specific keymaps should go in their plugin spec files instead -- this file is for general-purpose keymaps only.

```lua
local map = vim.keymap.set

-- Easier command prompt
map({ "n", "v" }, ";", ":")

-- Quick escape
map("i", "jj", "<Esc>")

-- Quick save
map("n", "<Leader>w", "<cmd>w<CR>", { desc = "Save file" })

-- Quick visual mode (line-select)
map("n", "<Leader><Leader>", "V", { desc = "Visual line mode" })

-- Reload config
map("n", "<Leader>s", "<cmd>source $MYVIMRC<CR>", { desc = "Source config" })
map("n", "<Leader>vi", "<cmd>tabedit $MYVIMRC<CR>", { desc = "Edit config" })

-- Swap ' and ` for marks (jump to column vs line)
map({ "n", "v", "o" }, "'", "`")
map({ "n", "v", "o" }, "`", "'")
map({ "n", "v", "o" }, "g'", "g`")
map({ "n", "v", "o" }, "g`", "g'")

-- Jump to end of line in insert mode
map("i", "<C-j>", "<End>")

-- Make Q useful
map("n", "QQ", "<cmd>q<CR>", { desc = "Close window" })
map("n", "QW", "<cmd>windo bd<CR>", { desc = "Close tab" })
map("n", "QA", "<cmd>qa<CR>", { desc = "Close all" })
map("n", "Q!", "<cmd>q!<CR>", { desc = "Force close" })

-- NOTE: the old config had these conflicts:
--   Line 27: noremap Q <nop>
--   Line 132: noremap Q gq      <-- this overwrites the <nop>
-- Dropping both. QQ/QW/QA handle the useful cases.
-- For `gq` formatting: use <Leader>fef or gq with a motion directly.

-- Clipboard (system)
map({ "n", "v" }, "<Leader>y", '"+y', { desc = "Yank to clipboard" })
map({ "n", "v" }, "<Leader>p", '"+p', { desc = "Paste from clipboard" })
map({ "n", "v" }, "<Leader>P", '"+P', { desc = "Paste before from clipboard" })
map("v", "<Leader>d", '"+d', { desc = "Cut to clipboard" })

-- NOTE: the old config had <Leader>p mapped twice:
--   Line 41: paste-with-nopaste workaround (no longer needed with clipboard=unnamedplus)
--   Line 175: "+p
-- Using "+p since clipboard=unnamedplus handles the paste-mode issue.

-- Default searches to "very magic"
map({ "n", "v" }, "?", "?\\v")

-- Select last edited/pasted text
map("n", "gV", "`[v`]", { desc = "Select last changed text" })

-- NOTE: gV was defined twice (lines 51 and 181). Same mapping, no conflict.

-- tmux navigator fix for neovim
map("n", "<BS>", "<cmd>TmuxNavigateLeft<CR>", { silent = true })

-- No help on F1
map({ "n", "i", "c" }, "<F1>", "<Esc>")

-- Emacs-like line movement in insert mode
map("i", "<C-e>", "<C-o>$")
map("i", "<C-a>", "<C-o>^")

-- Tab navigation
map("n", "<S-Left>", "<cmd>tabp<CR>")
map("n", "<S-Right>", "<cmd>tabn<CR>")
map("n", "<Leader>tn", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<Leader>tp", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<Leader>te", ":tabedit ", { desc = "Edit in new tab" })

-- NOTE: dropping MacVim-specific <D-#> tab bindings (going neovim-only).
-- Also dropping <C-#> tab bindings (most conflict with terminal sequences).

-- Clear search highlight
map("n", "<C-L>", "<cmd>nohls<CR><C-L>", { desc = "Clear highlights" })
map("n", "<CR>", "<cmd>noh<CR><CR>", { desc = "Clear search on enter" })
map("n", "<Leader>hs", "<cmd>set hlsearch! hlsearch?<CR>", { desc = "Toggle hlsearch" })

-- Make Y consistent with C and D
map("n", "Y", "y$")

-- Keep selection when indenting
map("v", ">", ">gv")
map("v", "<", "<gv")

-- Format entire file
map("n", "<Leader>fef", "<cmd>normal! gg=G``<CR>", { desc = "Format entire file" })

-- Upper/lower word
map("n", "<Leader>u", "mQviwU`Q", { desc = "Uppercase word" })
map("n", "<Leader>l", "mQviwu`Q", { desc = "Lowercase word" })
map("n", "<Leader>U", "mQgewvU`Q", { desc = "Uppercase first char" })
map("n", "<Leader>L", "mQgewvu`Q", { desc = "Lowercase first char" })

-- cd to buffer's directory
map("n", "<Leader>cd", "<cmd>lcd %:h<CR>", { silent = true, desc = "cd to buffer dir" })

-- Toggle wrap
map("n", "<Leader>tw", "<cmd>set invwrap<CR><cmd>set wrap?<CR>", { silent = true, desc = "Toggle wrap" })

-- Find merge conflict markers
map("n", "<Leader>fc", [[<cmd>silent! /\v^[<=>]{7}( .*|$)<CR>]], { silent = true, desc = "Find merge conflicts" })

-- Toggle relative line numbers
map("n", "<C-G>", function()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative numbers" })

-- Increment/decrement with repeat support
-- The old AddSubtract function is complex. Simplified version:
map("n", "<C-a>", "<C-a>")   -- keep defaults; vim-repeat handles these natively
map("n", "<C-x>", "<C-x>")
```

### Keymap Conflicts Found and Resolved

| Keys | Conflict | Resolution |
|---|---|---|
| `s` | Mapped to both `easymotion-s` and `easymotion-s2` (line 139 then 143) | Second wins. Moving to flash.nvim -- see [03-navigation](03-navigation.md) |
| `Q` | Mapped to `<nop>` (line 27), then `gq` (line 132) | Both dropped. `QQ`/`QW`/`QA` remain. Use `gq{motion}` directly. |
| `<Leader>p` | Paste-with-nopaste (line 41) and clipboard `"+p` (line 175) | Keep `"+p` only. `clipboard=unnamedplus` eliminates the paste-mode hack. |
| `gV` | Defined twice (lines 51 and 181) | Same mapping both times. Keep once. |
| `/` | EasyMotion overrides to `easymotion-sn` (plugins.vim line 153) | **Drops native incremental search.** flash.nvim does NOT override `/` -- conflict gone. |
| `<Leader>f` | Mapped to `:Ack!` (plugins.vim line 16) | Remapping to telescope `live_grep` in [03-navigation](03-navigation.md) |

## `lua/autocmds.lua`

Port from `vimfiles/config/autocommands.vim` (67 lines) and the line proximity highlights in `.vimrc`.

```lua
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Remember last cursor position (except commit messages)
local restore_group = augroup("RestoreCursor", { clear = true })
autocmd("BufReadPost", {
  group = restore_group,
  callback = function()
    if vim.bo.filetype == "gitcommit" then return end
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Filetype overrides
local ft_group = augroup("FiletypeOverrides", { clear = true })

autocmd("FileType", {
  group = ft_group,
  pattern = "make",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

autocmd("FileType", {
  group = ft_group,
  pattern = "python",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.softtabstop = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})

-- Ruby file detection
autocmd({ "BufRead", "BufNewFile" }, {
  group = ft_group,
  pattern = { "Gemfile", "Rakefile", "Vagrantfile", "Thorfile", "Procfile", "config.ru", "*.rake", "*.god", "*.bldr" },
  callback = function()
    vim.bo.filetype = "ruby"
  end,
})

-- Markdown wrapping
autocmd({ "BufRead", "BufNewFile" }, {
  group = ft_group,
  pattern = { "*.md", "*.markdown", "*.mdown", "*.mkd", "*.mkdn", "*.txt" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.textwidth = 80
    vim.opt_local.list = false
  end,
})

-- Crontab: no backup (fixes crontab -e)
autocmd("FileType", {
  group = ft_group,
  pattern = "crontab",
  callback = function()
    vim.opt_local.backup = false
    vim.opt_local.writebackup = false
  end,
})

-- Close help/man windows with q
autocmd("FileType", {
  group = ft_group,
  pattern = { "help", "man", "qf", "lspinfo", "startuptime" },
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>q<CR>", { buffer = event.buf, silent = true })
  end,
})

-- Auto-reload files changed outside vim
local reload_group = augroup("AutoReload", { clear = true })
autocmd({ "WinEnter", "BufWinEnter", "CursorHold" }, {
  group = reload_group,
  command = "checktime",
})

-- Equalize splits on resize
autocmd("VimResized", {
  group = augroup("ResizeEqualize", { clear = true }),
  command = "wincmd =",
})

-- Highlight tech words to avoid in writing
-- http://css-tricks.com/words-avoid-educational-writing/
local techwords_group = augroup("TechWordsToAvoid", { clear = true })
autocmd({ "BufWinEnter", "InsertEnter", "InsertLeave" }, {
  group = techwords_group,
  callback = function()
    if vim.bo.buftype ~= "" then return end  -- skip special buffers
    vim.fn.matchadd(
      "TechWordsToAvoid",
      [[\cobviously\|basically\|simply\|of\scourse\|clearly\|just\|everyone\sknows\|however,\|so,\|easy]]
    )
  end,
})
autocmd("BufWinLeave", {
  group = techwords_group,
  callback = function()
    pcall(vim.fn.clearmatches)
  end,
})

-- The highlight definition goes in your colorscheme config or here:
vim.api.nvim_set_hl(0, "TechWordsToAvoid", { bg = "#902020", fg = "#ffffff" })

-- Line proximity and overflow highlighting
-- Port from .vimrc lines 148-160
vim.api.nvim_set_hl(0, "LineProximity", { bg = "#212121" })
vim.api.nvim_set_hl(0, "LineOverflow", { bg = "#902020" })

local proximity_group = augroup("LineProximity", { clear = true })
autocmd({ "WinEnter", "BufWinEnter" }, {
  group = proximity_group,
  callback = function()
    -- Clear existing matches to avoid duplicates
    pcall(vim.fn.clearmatches)
    vim.fn.matchadd("LineProximity", [[\%<121v.\%>116v]], -1)
    vim.fn.matchadd("LineOverflow", [[\%>120v.\+]], -1)
    -- Re-add tech words match
    if vim.bo.buftype == "" then
      vim.fn.matchadd(
        "TechWordsToAvoid",
        [[\cobviously\|basically\|simply\|of\scourse\|clearly\|just\|everyone\sknows\|however,\|so,\|easy]]
      )
    end
  end,
})
```

## `lua/commands.lua`

Port from `vimfiles/config/commands.vim` (43 lines).

```lua
local cmd = vim.api.nvim_create_user_command

-- Quick filetype setting: :F html
cmd("F", function(opts)
  vim.bo.filetype = opts.args
end, { nargs = 1, complete = "filetype" })

-- Quick filetype shortcuts
-- Dropping :FC (CoffeeScript) -- no longer needed
cmd("FH", function() vim.bo.filetype = "haml" end, {})
cmd("FR", function() vim.bo.filetype = "ruby" end, {})
cmd("FV", function() vim.bo.filetype = "vim" end, {})

-- Strip trailing whitespace
cmd("Strip", function()
  local save_cursor = vim.api.nvim_win_get_cursor(0)
  local save_search = vim.fn.getreg("/")
  vim.cmd([[%s/\s\+$//e]])
  vim.fn.setreg("/", save_search)
  vim.api.nvim_win_set_cursor(0, save_cursor)
  vim.cmd("nohl")
end, { desc = "Strip trailing whitespace" })

-- Convert Ruby 1.8 hash rockets to 1.9 style
cmd("NotRocket", function(opts)
  vim.cmd(opts.line1 .. "," .. opts.line2 .. [[s/:\(\w\+\)\s*=>/\1:/ge]])
end, { range = "%", desc = "Convert hash rockets to modern Ruby style" })

-- Save as root
-- The old cabbrev `w!!` doesn't translate well. Use a command instead:
cmd("SudoWrite", function()
  vim.cmd("w !sudo tee % > /dev/null")
  vim.cmd("e!")
end, { desc = "Save file as root" })
```

## Checklist

- [ ] Create `lua/keymaps.lua` with the mappings above
- [ ] Review keymap conflicts table -- confirm resolutions make sense
- [ ] Create `lua/autocmds.lua` with autocommands above
- [ ] Create `lua/commands.lua` with user commands above
- [ ] Update `init.lua` to require all three new files
- [ ] Test: open a Ruby file, verify it gets `ft=ruby`
- [ ] Test: `<Leader>w` saves, `jj` escapes, `;` opens command line
- [ ] Test: open a help window, press `q` to close
- [ ] Test: `:Strip` removes trailing whitespace
- [ ] Test: `:NotRocket` converts `:foo => 'bar'` to `foo: 'bar'`
- [ ] Test: tech words highlighting works (type "obviously" in a buffer)
- [ ] Test: line overflow highlighting appears past column 120
