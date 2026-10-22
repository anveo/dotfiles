-- GDScript uses hard tabs, 4-space width (Godot editor default)
vim.opt_local.expandtab = false
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.list = false

-- godotdev.nvim: K stays LSP hover, gK opens Godot class docs for the symbol under cursor
vim.keymap.set("n", "gK", "<cmd>GodotDocs<CR>", { buffer = true, desc = "Godot docs" })
