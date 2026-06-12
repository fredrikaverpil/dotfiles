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
  called = {},

  -- treesitter
  use_treesitter_parser = true,
  use_nvim_treesitter = true,
  use_arborist = false, -- experiment

  -- diffing
  use_diffview = false,
  use_codediff = true,

  -- lsp
  use_workspace_diagnostics_plugin = false,
}
function _G.Config.add(spec)
  require("merge")(_G.Config, spec)
end

vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("options")
require("keymaps")

-- Experimental: ui2 message/cmdline redesign (:h ui2)
-- Avoids "Press ENTER" prompts, highlights cmdline, pager as buffer.
require("vim._core.ui2").enable()
