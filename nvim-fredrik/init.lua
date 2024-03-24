-- set for neovim 0.10.0
-- TODO: remove once 0.10.0 is released
vim.uv = vim.uv or vim.loop

-- set options
require("config.options")

-- set auto commands
require("config.autocmds")

-- setup up package manager, load plugins and configs
require("config.lazy")
