-- 2-space indent for Ruby (overrides the 4-space default)
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2

-- String interpolation helper: # inside double-quotes becomes #{}
vim.keymap.set("i", "#", function()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  local before = line:sub(1, col - 1)
  local after = line:sub(col)
  if before:find('"') and after:find('"') then
    return "#{}<Left>"
  else
    return "#"
  end
end, { buffer = true, expr = true })

-- Surround with # (for vim-surround)
if vim.g.loaded_surround then
  vim.b["surround_" .. string.byte("#")] = "#{\\r}"
end
