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

-- Find all .lazy.lua files from cwd up to ~/, ordered general → specific
-- so that the most specific (closest to cwd) wins via lazy.nvim's merge order.
local function find_local_specs()
  local home = vim.uv.os_homedir()
  local dir = vim.uv.cwd()
  if not home or not dir then
    return {}
  end
  local found = {}
  while dir and #dir >= #home do
    local path = dir .. "/.lazy.lua"
    if vim.uv.fs_stat(path) then
      table.insert(found, path)
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end
  -- Reverse: load general (closer to ~/) first, specific (closer to cwd) last
  local reversed = {}
  for i = #found, 1, -1 do
    table.insert(reversed, found[i])
  end
  return reversed
end

local local_specs = find_local_specs()
local spec = {
  -- Merge order matters: later specs override earlier ones for the same plugin.
  -- plugins (defaults) → lang (language-specific) → core (final authority) → .lazy.nvim overrides
  { import = "fredrik.plugins" },
  { import = "fredrik.plugins.lang" },
  { import = "fredrik.plugins.core" },
}

-- Append local .lazy.lua specs (general → specific, so project-level wins)
local loaded_specs = {}
for _, path in ipairs(local_specs) do
  local ok, local_spec = pcall(dofile, path)
  if ok and local_spec then
    table.insert(spec, local_spec)
    table.insert(loaded_specs, path)
  end
end
if #loaded_specs > 0 then
  vim.g.local_lazy_specs = loaded_specs
end

require("lazy").setup({

  spec = spec,

  dev = {
    path = "~/code/public",
    fallback = true, -- Fallback to git when local plugin doesn't exist
  },

  -- import per-project config
  -- NOTE: this is built into lazy.nvim; place a .lazy.lua file in the project's
  -- root directory, containing a lazy spec and it will be merged in at the end of the above spec.
  -- This is set to `false` now, since we load the specs in custom fashion using `loaded_specs`.
  local_spec = false,

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
        "tutor",
        "zipPlugin",
      },
    },
  },
})
