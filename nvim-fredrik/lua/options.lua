-- Editor options.
-- Sourced from init.lua before any plugin/ files.

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- Tabs and indentation defaults (overridden per-filetype in ftplugin/)
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Undo and swap
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200

-- Display
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.winborder = "solid"
vim.opt.cursorline = false
vim.opt.wrap = false
vim.opt.linebreak = true
vim.opt.smoothscroll = true
vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:❯,precedes:❮"
vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  foldinner = " ",
  diff = "╱",
  eob = " ",
}
vim.opt.statuscolumn = "%C %s%=%l "

-- Folding (treesitter default; LSP override per-buffer via lua/fold.lua)
vim.opt.foldcolumn = "1"
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = "v:lua.require('fold').foldtext()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- Completion
vim.opt.completeopt = "menuone,noselect"

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Scroll
vim.opt.scrolloff = 4

-- Mouse
vim.opt.mouse = "a"
vim.opt.mousescroll = { "ver:1", "hor:6" }

-- Misc
vim.opt.autoread = true
vim.opt.exrc = false -- replaced by lua/exrc.lua
vim.opt.secure = true
vim.opt.shortmess:append("I")
vim.opt.timeoutlen = 300

-- Titlestring (Ghostty)
if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end
