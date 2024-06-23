local function set_dark()
  vim.api.nvim_set_option_value("background", "dark", {})
  vim.cmd.colorscheme("tokyonight-moon")
end

local function set_light()
  vim.api.nvim_set_option_value("background", "light", {})
  vim.cmd.colorscheme("dayfox")
end

return {
  {
    "folke/tokyonight.nvim",
    enabled = true,
    lazy = false,
    priority = 1000,
    init = function()
      set_dark() -- avoid flickering when starting nvim
    end,
  },
  {
    "catppuccin/nvim",
    enabled = true,
    name = "catppuccin", -- or Lazy will show the plugin as "nvim"
  },
  {
    "rose-pine/neovim",
    enabled = true,
    name = "rose-pine", -- or Lazy will show the plugin as "neovim"
  },
  {
    "EdenEast/nightfox.nvim",
    enabled = true,
  },
  {
    "f-person/auto-dark-mode.nvim",
    enabled = true,
    lazy = false,
    priority = 1000,
    dependencies = {},
    opts = {
      update_interval = 3000, -- milliseconds
      set_dark_mode = function()
        set_dark()
        os.execute("tmux source-file ~/.tmux/plugins/tokyonight.nvim/extras/tmux/tokyonight_moon.tmux")
        os.execute("cp $DOTFILES/lazygit_config_dark.yml $DOTFILES/lazygit_config.yml")
      end,
      set_light_mode = function()
        set_light()
        os.execute("tmux source-file ~/.tmux/plugins/tokyonight.nvim/extras/tmux/tokyonight_day.tmux")
        os.execute("cp $DOTFILES/lazygit_config_light.yml $DOTFILES/lazygit_config.yml")
      end,
    },
  },
}
