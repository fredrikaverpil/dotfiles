local function set_dark()
  -- Colorschemes with light background
  -- vim.o.background = "light"
  -- vim.cmd.colorscheme("tokyonight-moon")

  -- Colorschemes with dark background
  vim.o.background = "dark"
  -- vim.cmd.colorscheme("rose-pine")
  -- vim.cmd.colorscheme("everforest")
  -- vim.cmd.colorscheme("nordic")
  vim.cmd.colorscheme("zenbones")
end

local function set_light()
  vim.o.background = "light"

  -- vim.cmd.colorscheme("dayfox")

  -- vim.o.background = "light"
  -- vim.g.everforest_background = "hard"
  -- vim.cmd.colorscheme("everforest")

  vim.cmd.colorscheme("forestbones")
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
    enabled = false,
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
    enabled = false,
    name = "catppuccin",
  },
  {
    "rebelot/kanagawa.nvim",
    enabled = false,
  },
  {
    -- :h nightfox
    "EdenEast/nightfox.nvim",
    enabled = false,
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
    enabled = false,
    config = function()
      vim.g.everforest_background = "hard"
      vim.g.everforest_enable_italic = true
      -- vim.g.everforest_better_performance = 1
    end,
  },
  {
    "rose-pine/neovim",
    enabled = false,
    name = "rose-pine",
    opts = {
      enable = {
        legacy_highlights = false,
      },
      dim_inactive_windows = true,
    },
  },
  {
    "zenbones-theme/zenbones.nvim",
    enabled = true,
    dependencies = { "rktjmp/lush.nvim" },
    config = function()
      vim.g.zenbones = {
        lighten_comments = 25,
        italic_strings = false,
      }

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "zenbones", -- Only apply to zenbones, not forestbones or other variants
        group = vim.api.nvim_create_augroup("zenbones_overrides", { clear = true }),
        callback = function()
          vim.api.nvim_set_hl(0, "MiniCursorword", { underline = false, bg = "#3a3a3a" })

          -- vim.api.nvim_set_hl(0, "@constant", { fg = "#d08770" }) -- constants
          -- vim.api.nvim_set_hl(0, "@constant.builtin", { fg = "#d08770", italic = true }) -- builtin constants
          vim.api.nvim_set_hl(0, "@type", { fg = "#8fbcbb" }) -- type names
          vim.api.nvim_set_hl(0, "@type.builtin", { fg = "#8fbcbb", italic = true }) -- builtin types
          -- vim.api.nvim_set_hl(0, "@module", { fg = "#88c0d0", italic = true }) -- package names in imports
          vim.api.nvim_set_hl(0, "@variable.parameter", { italic = true }) -- function parameters
        end,
      })
    end,
  },
}
