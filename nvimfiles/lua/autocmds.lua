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
    if vim.bo.buftype ~= "" then return end
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

-- Line proximity and overflow highlighting
local proximity_group = augroup("LineProximity", { clear = true })
autocmd({ "WinEnter", "BufWinEnter" }, {
  group = proximity_group,
  callback = function()
    pcall(vim.fn.clearmatches)
    vim.fn.matchadd("LineProximity", [[\%<121v.\%>116v]], -1)
    vim.fn.matchadd("LineOverflow", [[\%>120v.\+]], -1)
    if vim.bo.buftype == "" then
      vim.fn.matchadd(
        "TechWordsToAvoid",
        [[\cobviously\|basically\|simply\|of\scourse\|clearly\|just\|everyone\sknows\|however,\|so,\|easy]]
      )
    end
  end,
})
