-- setup up package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- load and confgure plugins in this order (plugins, languages, core, project-specific overrides):
  spec = {
    -- import all plugins and their configs
    { import = "fredrik.plugins" },
    -- import language configs
    { import = "fredrik.plugins.lang" },
    -- import core configs
    { import = "fredrik.plugins.core" },
  },

  dev = {
    path = "~/code/public",
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },

  -- import per-project config
  -- NOTE: this is built into lazy.nvim; place a .lazy.lua file in the project's
  -- root directory, containing a lazy spec and it will be merged in at the end of the above spec.
  local_spec = true,

  checker = { enabled = false }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        "matchit", -- match-up replaces this
        "matchparen", -- match-up replaces this
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
