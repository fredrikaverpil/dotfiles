-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- skip startup screen
vim.opt.shortmess:append("I")

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- set tab and indents defaults (can be overridden by per-language configs)
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- column ruler (can be overridden by per-language configs)
vim.opt.colorcolumn = "80"

-- incremental search
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- ignore case when searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- text wrap
vim.opt.wrap = false

-- completion
vim.opt.completeopt = "menuone,noselect"

-- 24-bit color
vim.opt.termguicolors = true

-- sign column
vim.opt.signcolumn = "yes"

-- cursor line highlight
vim.opt.cursorline = true

-- splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- fold settings
-- vim.opt.foldcolumn = 0
-- vim.opt.foldmethod = "indent"
-- vim.opt.foldlevel = 99
-- vim.opt.foldlevelstart = 99
-- vim.opt.foldenable = true

-- scroll off
vim.opt.scrolloff = 8

-- mouse support in all modes
vim.opt.mouse = "a"

-- project specific settings (see lazyrc.lua for .lazy.lua support)
vim.opt.exrc = true -- allow local .nvim.lua .vimrc .exrc files
vim.opt.secure = true -- disable shell and write commands in local .nvim.lua .vimrc .exrc files

-- sync with system clipboard (also see autocmds for text yank config)
vim.opt.clipboard = "unnamedplus"

-- TODO: pick from https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:❯,precedes:❮" -- show symbols for whitespace
