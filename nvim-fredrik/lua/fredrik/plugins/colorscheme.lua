---@return nil
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

---@return nil
local function set_light()
  vim.o.background = "light"

  -- vim.cmd.colorscheme("dayfox")

  -- vim.o.background = "light"
  -- vim.g.everforest_background = "hard"
  -- vim.cmd.colorscheme("everforest")

  vim.cmd.colorscheme("zenbones")
end

---@return boolean
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

---@param style "dark"|"light"
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
      local lush = require("lush")

      local function apply_overrides()
        local colors_name = vim.g.colors_name
        if not colors_name then
          return
        end

        local ok, palette_mod = pcall(require, colors_name .. ".palette") -- kind of like require("zenbones.palette")
        if not ok then
          return
        end

        local palette = palette_mod[vim.o.background]
        if not palette then
          return
        end

        local spec = lush.extends({ require(colors_name) }).with(function(injected_functions)
          ---@type fun(name: string): fun(def: table): any
          local sym = injected_functions.sym
          return {
            -- Docs: https://github.com/zenbones-theme/zenbones.nvim/blob/main/doc/zenbones.md
            -- Palette: https://github.com/zenbones-theme/zenbones.nvim/blob/main/lua/zenbones/util.lua
            -- Use :Inspect to see what highlight groups are being used where.
            --
            -- Palette notes:
            -- * Base colors (rose, wood, etc.) are the standard shades.
            -- * "1" variants (rose1, wood1, etc.) are more saturated and higher contrast:
            --   - Dark mode: Lighter (+16) and more saturated (+20)
            --   - Light mode: Darker (-16) and more saturated (+20)
            -- * fg1 is lower contrast (dimmer) than fg.
            -- * bg1 is higher contrast (lighter in dark mode, darker in light mode) than bg.

            sym("@comment")({ fg = palette.bg.mix(palette.fg, 45), gui = "NONE" }),

            sym("MiniCursorword")({ bg = palette.bg.mix(palette.bg1, 90), underline = false }),

            sym("NeotestPassed")({ fg = palette.leaf }),
            sym("NeotestFailed")({ fg = palette.rose }),
            sym("NeotestRunning")({ fg = palette.wood }),
            sym("NeotestSkipped")({ fg = palette.sky }),
            sym("NeotestFile")({ fg = palette.sky }),
            sym("NeotestDir")({ fg = palette.water }),
            sym("NeotestNamespace")({ fg = palette.blossom }),
            sym("NeotestFocused")({ gui = "bold,underline" }),
            sym("NeotestAdapterName")({ fg = palette.rose }),
            sym("NeotestWinSelect")({ fg = palette.sky, gui = "bold" }),
            sym("NeotestMarked")({ fg = palette.wood, gui = "bold" }),
            sym("NeotestTarget")({ fg = palette.rose }),
            sym("NeotestUnknown")({ fg = palette.bg.mix(palette.fg, 50) }),
            sym("NeotestExpandMarker")({ fg = palette.bg.mix(palette.fg, 50) }),
          }
        end)

        lush(spec)
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = { "zenbones", "zenwritten", "zenburned", "*bones" },
        group = vim.api.nvim_create_augroup("zenbones_overrides", { clear = true }),
        callback = apply_overrides,
      })

      -- Apply immediately if the current scheme matches
      apply_overrides()
    end,
  },
}
