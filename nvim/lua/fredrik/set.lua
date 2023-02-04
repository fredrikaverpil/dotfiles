-- line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- tabs and indents
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- line wrapping
vim.opt.wrap = false

-- search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- appearance
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "88"

-- backspace, make it behave like most other editors
vim.opt.backspace = "indent,eol,start"

-- copy/paste to system clipboard
vim.opt.clipboard:append("unnamedplus")

-- consider dash being part of a word
vim.opt.iskeyword:append("-")

-- scrolling
vim.opt.scrolloff = 8


vim.opt.isfname:append("@-@")

-- faster update time
vim.opt.updatetime = 50

-- show whitespace
vim.opt.list = true
vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:❯,precedes:❮"

-- diagnostics
-- vim.diagnostic.config({
--     virtual_text = true,
--     signs = true,
--     update_in_insert = false,
--     underline = true,
--     severity_sort = false,
--     float = true,
--   })
