local M = {}

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
  fold = " ", -- hide the ·············· that shows for folded code
  foldsep = " ", -- hide the vertical line where a fold is possible
  foldinner = " ", -- hide the indentation numbers in the fold column
  diff = "╱",
  -- diff = "░",
  -- diff = "·",
  eob = " ",
}

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- set tab and indents defaults (can be overridden by per-language configs)
vim.opt.tabstop = 4 -- display tabs as 4 spaces
vim.opt.softtabstop = 4 -- insert 4 spaces when tab is pressed
vim.opt.shiftwidth = 4 -- indent << or >> by 4 spaces
vim.opt.expandtab = false -- expand tab into spaces

-- vim.opt.colorcolumn = "80"

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

-- rounded corners on floating windows
vim.opt.winborder = "solid"

-- cursor line highlight
vim.opt.cursorline = false

-- Enable cursor blinking in all modes
--
-- The numbers represent milliseconds:
-- blinkwait175: Time before blinking starts
-- blinkoff150: Time cursor is invisible
-- blinkon175: Time cursor is visible
-- vim.opt.guicursor = "n-v-c-sm:block-blinkwait175-blinkoff150-blinkon175"

-- splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- set up diagnostics
require("fredrik.utils.diagnostics").setup_diagnostics()

-- set up folding
function _G.custom_foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local line_count = vim.v.foldend - vim.v.foldstart + 1
  local line_text = vim.fn.substitute(line, "\t", " ", "g")
  return string.format("%s (%d lines)", line_text, line_count)
end
-- Treesitter folding is the global default. LSP folding overrides per-buffer
-- via lsp_foldexpr(), called from plugins/core/lsp.lua when the server
-- supports textDocument/foldingRange.
vim.opt.foldcolumn = "1" -- "0" to hide, "auto" to show when folds exist, "1" for always visible
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = "v:lua.custom_foldtext()"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

--- Override foldexpr with LSP folding for the current window/buffer.
---@param win integer window handle
function M.lsp_foldexpr(win)
  vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
end

-- scroll off
vim.opt.scrolloff = 4

-- mouse support in all modes
vim.opt.mouse = "a"

-- scroll 1 line at a time
vim.opt.mousescroll = { "ver:1", "hor:6" }

-- project specific settings (see lazyrc.lua for .lazy.lua support)
vim.opt.exrc = true -- allow local .nvim.lua .vimrc .exrc files
vim.opt.secure = true -- disable shell and write commands in local .nvim.lua .vimrc .exrc files

-- auto read files changed outside of nvim
vim.opt.autoread = true

-- sync with system clipboard
-- NOTE: https://github.com/neovim/neovim/issues/11804
vim.opt.clipboard = "unnamedplus"

-- TODO: pick from https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
vim.opt.listchars = "tab:▸ ,trail:·,nbsp:␣,extends:❯,precedes:❮" -- show symbols for whitespace

-- NOTE: see auto session for vim.o.sessionoptions

vim.opt.smoothscroll = true

if not vim.g.vscode then
  vim.opt.timeoutlen = 300 -- Lower than default (1000) to quickly trigger which-key
end

-- set titlestring to $cwd if TERM_PROGRAM=ghostty
if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
  vim.opt.title = true
  vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')}"
end

return M
