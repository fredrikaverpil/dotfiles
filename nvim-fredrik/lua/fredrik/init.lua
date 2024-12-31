-- debugging of config;
-- 1. start neovim: nvim --cmd "lua init_debug=true" (starts server)
-- 2. start another neovim instance normally, set break points
-- 3. run require("dap").continue() (<leader>dc)
--
---@diagnostic disable-next-line: undefined-global
if init_debug then
  local osvpath = vim.fn.stdpath("data") .. "/lazy/one-small-step-for-vimkind"
  vim.opt.rtp:prepend(osvpath)
  require("osv").launch({ port = 8086, blocking = true })
end

-- set up backwards compatibility
require("fredrik.utils.version").setup_backwards_compat()

-- set options
require("fredrik.config.options")

-- set auto commands
require("fredrik.config.autocmds")

-- setup up plugin manager, load plugin configs
require("fredrik.config.lazy")
