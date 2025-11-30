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
    config = function()
      vim.g.bones_compat = 1 -- do not rely on lush.nvim (use built-in vim highlight API) instead
      local colors = require("fredrik.utils.colors")

      local function apply_overrides()
        local colors_name = vim.g.colors_name
        if not colors_name then
          return
        end

        -- Define palette locally to avoid lush dependency
        -- Dynamically extract colors from terminal colors set by the theme
        -- Mapping based on zenbones/term.lua
        local palette = {
          bg = vim.g.terminal_color_0,
          rose = vim.g.terminal_color_1,
          leaf = vim.g.terminal_color_2,
          wood = vim.g.terminal_color_3,
          water = vim.g.terminal_color_4,
          blossom = vim.g.terminal_color_5,
          sky = vim.g.terminal_color_6,
          fg = vim.g.terminal_color_7,
          bg1 = vim.g.terminal_color_8,
          rose1 = vim.g.terminal_color_9,
          leaf1 = vim.g.terminal_color_10,
          wood1 = vim.g.terminal_color_11,
          water1 = vim.g.terminal_color_12,
          blossom1 = vim.g.terminal_color_13,
          sky1 = vim.g.terminal_color_14,
          fg1 = vim.g.terminal_color_15,
        }

        -- Fallback if terminal colors are not set (should not happen with zenbones themes)
        if not palette.bg then
          return
        end

        -- Docs: https://github.com/zenbones-theme/zenbones.nvim/blob/main/doc/zenbones.md
        -- Palette: https://github.com/zenbones-theme/zenbones.nvim/blob/main/lua/zenbones/util.lua
        -- Use :Inspect to see what highlight groups are being used where.

        ---@param group string
        ---@param opts table
        local function hl(group, opts)
          vim.api.nvim_set_hl(0, group, opts)
        end

        hl("Comment", { fg = colors.blend(palette.bg, palette.fg, 40), italic = true })
        hl("@comment", { link = "Comment" })

        hl("MiniCursorword", { bg = colors.blend(palette.bg, palette.bg1, 90), underline = false })

        hl("NeotestPassed", { fg = palette.leaf })
        hl("NeotestFailed", { fg = palette.rose })
        hl("NeotestRunning", { fg = palette.wood })
        hl("NeotestSkipped", { fg = palette.sky })
        hl("NeotestFile", { fg = palette.sky })
        hl("NeotestDir", { fg = palette.water })
        hl("NeotestNamespace", { fg = palette.blossom })
        hl("NeotestFocused", { bold = true, underline = true })
        hl("NeotestAdapterName", { fg = palette.rose })
        hl("NeotestWinSelect", { fg = palette.sky, bold = true })
        hl("NeotestMarked", { fg = palette.wood, bold = true })
        hl("NeotestTarget", { fg = palette.rose })
        hl("NeotestUnknown", { fg = colors.blend(palette.bg, palette.fg, 50) })
        hl("NeotestExpandMarker", { fg = colors.blend(palette.bg, palette.fg, 50) })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = { "zenbones", "zenwritten", "zenburned", "*bones" },
        group = vim.api.nvim_create_augroup("zenbones_overrides", { clear = true }),
        callback = function()
          vim.schedule(apply_overrides)
        end,
      })

      -- Apply immediately if the current scheme matches
      vim.schedule(apply_overrides)
    end,
  },
}
