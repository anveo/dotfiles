local cmd = vim.api.nvim_create_user_command

-- Quick filetype setting: :F html
cmd("F", function(opts)
  vim.bo.filetype = opts.args
end, { nargs = 1, complete = "filetype" })

-- Quick filetype shortcuts
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
cmd("SudoWrite", function()
  vim.cmd("w !sudo tee % > /dev/null")
  vim.cmd("e!")
end, { desc = "Save file as root" })
