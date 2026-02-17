-- 2-space indent for TSX
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.opt_local.tabstop = 2

-- Dispatch default: vitest for test files, tsc for others
if not vim.b.dispatch then
  local file = vim.fn.expand("%:t")
  if file:match("%.test%.tsx$") or file:match("%.spec%.tsx$") then
    vim.b.dispatch = "npx vitest run %"
  else
    vim.b.dispatch = "npx tsc --noEmit"
  end
end
