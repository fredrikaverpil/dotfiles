local function set_dark()
  -- vim.o.background = "light" -- NOTE: tokyonight-moon uses light background
  -- vim.cmd.colorscheme("tokyonight-moon")

  -- vim.o.background = "dark"
  -- vim.cmd.colorscheme("rose-pine")

  vim.o.background = "dark"
  vim.g.everforest_background = "hard"
  vim.cmd.colorscheme("everforest")
end

local function set_light()
  -- vim.o.background = "light"
  -- vim.cmd.colorscheme("dayfox")

  vim.o.background = "light"
  vim.g.everforest_background = "hard"
  vim.cmd.colorscheme("everforest")
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
    tmux_theme = vim.fn.expand("~/.local/share/nvim-fredrik/lazy/tokyonight.nvim/extras/tmux/tokyonight_moon.tmux")
  elseif style == "light" then
    tmux_theme = vim.fn.expand("~/.local/share/nvim-fredrik/lazy/nightfox.nvim/extra/dayfox/dayfox.tmux")
  end

  if vim.fn.filereadable(tmux_theme) == 1 then
    os.execute("tmux source-file " .. tmux_theme)
  end
end

return {
  -- color scheme managers
  {
    "afonsofrancof/OSC11.nvim",
    init = function()
      set_dark() -- avoid flickering when starting nvim, default to dark mode
    end,
    opts = {
      -- Function to call when switching to dark theme
      on_dark = function()
        set_dark()
        set_tmux("dark")
      end,
      -- Function to call when switching to light theme
      on_light = function()
        set_light()
        set_tmux("light")
      end,
    },
  },

  -- color schemes
  {
    -- :h tokyonight.nvim-table-of-contents
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
    -- :h nightfox
    "EdenEast/nightfox.nvim",
    enabled = true,
    lazy = true,
    opts = {
      options = {
        styles = {
          comments = "italic",
        },
      },
    },
  },
  {
    -- :h everforest
    "sainnhe/everforest",
    -- enabled = false,
    lazy = false,
    config = function()
      vim.g.everforest_enable_italic = true
      -- vim.g.everforest_better_performance = 1
    end,
  },
  {
    "rose-pine/neovim",
    enabled = false,
    name = "rose-pine",
    lazy = true,
    opts = {
      enable = {
        legacy_highlights = false,
      },
      dim_inactive_windows = true,
    },
  },
}
