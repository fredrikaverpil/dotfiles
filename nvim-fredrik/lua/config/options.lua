M = {}

-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- undo
vim.opt.undofile = true
vim.opt.undolevels = 10000
vim.opt.updatetime = 200 -- Save swap file and trigger CursorHold

-- skip startup screen
vim.opt.shortmess:append("I")

-- fillchars
vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  -- fold = "⸱",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  -- diff = "╱",
  -- diff = "░",
  -- diff = "·",
  eob = " ",
}

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
vim.opt.linebreak = true -- Wrap lines at convenient points

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
-- see ufo.lua

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

M.setup_folding_options = function()
  vim.opt.foldcolumn = "0"
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99
  vim.opt.foldenable = true
end

if require("utils.version").is_neovim_0_10_0() then
  vim.opt.smoothscroll = true
end

if not vim.g.vscode then
  vim.opt.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
end

return M
