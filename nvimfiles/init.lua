-- Ensure nvimfiles/ is on the runtime path (needed for `nvim -u` usage)
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
vim.opt.rtp:prepend(config_dir)

require("options")
require("keymaps")
require("autocmds")
require("commands")
require("config.lazy")
