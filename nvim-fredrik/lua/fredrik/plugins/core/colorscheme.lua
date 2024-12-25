local function set_dark()
  vim.cmd.colorscheme("tokyonight-moon") -- NOTE: this is the default for dark mode.
end

local function set_light()
  vim.cmd.colorscheme("dayfox") -- NOTE: this is the default for light mode.
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
        local tmux_theme = vim.fn.expand("~/.tmux/plugins/tokyonight.nvim/extras/tmux/tokyonight_moon.tmux")
        if tmux_is_running() and vim.fn.filereadable(tmux_theme) == 1 then
          os.execute("tmux source-file " .. tmux_theme)
        end
      end,
      set_light_mode = function()
        set_light()
        local tmux_theme = vim.fn.expand("~/.local/share/fredrik/lazy/nightfox.nvim/extra/dayfox/dayfox.tmux")
        if tmux_is_running() and vim.fn.filereadable(tmux_theme) == 1 then
          os.execute("tmux source-file " .. tmux_theme)
        end
      end,
    },
  },
  {
    "folke/tokyonight.nvim",
    enabled = true,
    lazy = true,
    opts = {
      -- transparent = true, -- Enable transparency
      -- styles = {
      --   -- Background styles. Can be "dark", "transparent" or "normal"
      --   sidebars = "dark",
      --   floats = "transparent",
      -- },
      dim_inactive = true, -- dims inactive windows
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
    "rose-pine/neovim",
    enabled = true,
    lazy = true,
    name = "rose-pine", -- or Lazy will show the plugin as "neovim"
  },
  {
    "EdenEast/nightfox.nvim",
    lazy = true,
  },
  {
    "zenbones-theme/zenbones.nvim",
    enabled = true,
    lazy = true,
    dependencies = {
      "rktjmp/lush.nvim",
    },
  },
}
