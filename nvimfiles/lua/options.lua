vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.numberwidth = 3

-- Indentation (4-space default; Ruby overridden in after/ftplugin/ruby.lua)
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.autoindent = true

-- Search
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Display
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.showmode = true
vim.opt.showcmd = true
vim.opt.termguicolors = true
vim.opt.list = true
vim.opt.listchars = { tab = "»·", trail = "·" }
vim.opt.colorcolumn = "120"

-- Scrolling
vim.opt.scrolloff = 999
vim.opt.scrolljump = 5

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Buffers
vim.opt.hidden = true

-- Folding (treesitter-based)
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldenable = true

-- Command-line completion
vim.opt.wildmode = "list:longest,full"
vim.opt.wildmenu = true
vim.opt.wildignore:append({
  "*~", "*.scssc", "*.sassc", "*.png", "*.PNG", "*.JPG", "*.jpg",
  "*.GIF", "*.gif", "*.dat", "*.doc", "*.DOC", "*.log", "*.pdf",
  "*.PDF", "*.ppt", "*.docx", "*.pptx", "*.wpd", "*.zip", "*.rtf",
  "*.eps", "*.psd", "*.ttf", "*.otf", "*.eot", "*.svg", "*.woff",
  "*.mp3", "*.mp4", "*.m4a", "*.wav",
  "log/**", "vendor/**", "coverage/**", "tmp/**",
})

-- History and undo
vim.opt.history = 1000
vim.opt.undofile = true

-- Misc
vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.mouse = "a"
vim.opt.complete:remove("i")
vim.opt.nrformats = { "bin", "hex", "alpha" }
vim.opt.clipboard = "unnamedplus"
vim.opt.virtualedit = "block"
vim.opt.inccommand = "split"

-- Temp files
vim.opt.directory = "/tmp/"

-- Encoding
vim.opt.encoding = "utf8"

-- Grep program
vim.opt.grepprg = "rg --vimgrep --smart-case"
vim.opt.grepformat = "%f:%l:%c:%m"
