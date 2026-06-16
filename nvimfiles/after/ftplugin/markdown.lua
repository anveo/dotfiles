-- Toggle browser live preview (markdown-preview.nvim)
-- <C-p> (the plugin's README default) is taken by Telescope find_files,
-- so use a buffer-local leader mapping instead.
vim.keymap.set("n", "<Leader>mp", "<cmd>MarkdownPreviewToggle<CR>", {
  buffer = true,
  desc = "Markdown preview (toggle)",
})
