return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    init = function()
      -- NOTE: avoid flickering when starting Neovim (in dark mode)
      vim.cmd.colorscheme("tokyonight-moon")
    end,
  },

  {
    "catppuccin/nvim",
    enabled = false,
    name = "catppuccin",
  },

  {
    "rose-pine/neovim",
    enabled = false,
    name = "rose-pine",
  },

  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    priority = 1000,
    dependencies = {},
    config = {
      update_interval = 3000, -- milliseconds
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd.colorscheme("tokyonight-moon")
        os.execute("tmux source-file ~/.tmux/plugins/tokyonight.nvim/extras/tmux/tokyonight_moon.tmux")
        os.execute("cp $DOTFILES/lazygit_config_dark.yml $DOTFILES/lazygit_config.yml")
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd.colorscheme("tokyonight-day")
        os.execute("tmux source-file ~/.tmux/plugins/tokyonight.nvim/extras/tmux/tokyonight_day.tmux")
        os.execute("cp $DOTFILES/lazygit_config_light.yml $DOTFILES/lazygit_config.yml")
      end,
    },
  },
}
