local function set_dark()
  vim.o.background = "light" -- NOTE: tokyonight-moon uses light background
  vim.cmd.colorscheme("tokyonight-moon")
end

local function set_light()
  vim.o.background = "light"
  vim.cmd.colorscheme("dayfox")
end

local function tmux_is_running()
  local processes = vim.fn.systemlist("ps -e | grep tmux")
  local found = false
  for _, process in ipairs(processes) do
    if string.find(process, "grep") then
      -- do nothing, just skip
    elseif string.find(process, "tmux") then
      found = true
    end
  end
  return found
end

local function set_tmux(style)
  if not tmux_is_running() then
    return
  end

  local tmux_theme = ""
  if style == "dark" then
    tmux_theme = vim.fn.expand("~/.local/share/fredrik/lazy/tokyonight.nvim/extras/tmux/tokyonight_moon.tmux")
  elseif style == "light" then
    tmux_theme = vim.fn.expand("~/.local/share/fredrik/lazy/nightfox.nvim/extra/dayfox/dayfox.tmux")
  end

  if vim.fn.filereadable(tmux_theme) == 1 then
    os.execute("tmux source-file " .. tmux_theme)
  end
end

return {
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    enabled = true,
    priority = 1000,
    dependencies = {},
    init = function()
      set_dark() -- avoid flickering when starting nvim, default to dark mode
    end,
    opts = {
      update_interval = 3000, -- milliseconds
      set_dark_mode = function()
        set_dark()
        set_tmux("dark")
      end,
      set_light_mode = function()
        set_light()
        set_tmux("light")
      end,
    },
  },
  {
    "uga-rosa/ccc.nvim",
    enabled = false, -- NOTE: enable when needed
    opts = {
      highlighter = {
        auto_enable = true,
        lsp = true,
      },
    },
    config = function(_, opts)
      local ccc = require("ccc")
      ccc.setup(opts)
    end,
  },
  {
    "folke/tokyonight.nvim",
    enabled = true,
    lazy = true,
    ---@class tokyonight.Config
    opts = {
      transparent = false, -- Enable transparency
      styles = {
        -- Background styles. Can be "dark", "transparent" or "normal"
        sidebars = "dark",
        floats = "dark",
      },
      dim_inactive = false, -- dims inactive windows
    },
  },
  {
    "catppuccin/nvim",
    enabled = true,
    lazy = true,
    name = "catppuccin", -- or Lazy will show the plugin as "nvim"
    opts = {
      -- transparent_background = true,
    },
  },
  {
    "EdenEast/nightfox.nvim",
    enabled = true,
    lazy = true,
  },
}
