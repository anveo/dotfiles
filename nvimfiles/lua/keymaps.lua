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

-- Clipboard (system)
map({ "n", "v" }, "<Leader>y", '"+y', { desc = "Yank to clipboard" })
map({ "n", "v" }, "<Leader>p", '"+p', { desc = "Paste from clipboard" })
map({ "n", "v" }, "<Leader>P", '"+P', { desc = "Paste before from clipboard" })
map("v", "<Leader>d", '"+d', { desc = "Cut to clipboard" })

-- Default searches to "very magic"
map({ "n", "v" }, "?", "?\\v")

-- Select last edited/pasted text
map("n", "gV", "`[v`]", { desc = "Select last changed text" })

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
