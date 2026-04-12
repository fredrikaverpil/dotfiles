-- Debugging and profiling of config
require("debug_config")
require("profile_config")

-- Before anything;
local nvim_start_time = vim.uv.hrtime()

-- Experimental Lua module loader.
vim.loader.enable()

-- States for this Neovim config.
_G.Config = {
  nvim_start_time = nvim_start_time,
  use_nvim_treesitter = true,
  called = {},
}

vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("options")
require("keymaps")
require("exrc").load()

-- Experimental: ui2 message/cmdline redesign (:h ui2)
-- Avoids "Press ENTER" prompts, highlights cmdline, pager as buffer.
require("vim._core.ui2").enable()
