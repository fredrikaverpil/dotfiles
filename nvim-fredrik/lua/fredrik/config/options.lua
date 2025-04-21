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
  -- diff = "╱",
  -- diff = "╱",
  diff = "░",
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

-- NOTE: do not set a global ruler here, as it will show in undesirable places.
-- Instead, set this in the per-language config files.
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
function M.treesitter_foldexpr()
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.opt_local.foldtext = "v:lua.custom_foldtext()"
end
function M.lsp_foldexpr()
  vim.opt_local.foldmethod = "expr"
  vim.opt_local.foldexpr = "v:lua.vim.lsp.foldexpr()"
  vim.opt_local.foldtext = "v:lua.custom_foldtext()"
end
vim.opt.foldcolumn = "0"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- scroll off
vim.opt.scrolloff = 4

-- mouse support in all modes
vim.opt.mouse = "a"

-- project specific settings (see lazyrc.lua for .lazy.lua support)
vim.opt.exrc = true -- allow local .nvim.lua .vimrc .exrc files
vim.opt.secure = true -- disable shell and write commands in local .nvim.lua .vimrc .exrc files

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
