local function set_dark()
  vim.cmd.colorscheme("tokyonight-moon")
end

local function set_light()
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
    "zenbones-theme/zenbones.nvim",
    dependencies = {
      "rktjmp/lush.nvim",
    },
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
        vim.g.lazygit_use_custom_config_file_path = 1
        local dark_theme = vim.fs.normalize("$DOTFILES/lazygit_config_dark.yml")
        vim.g.lazygit_config_file_path = dark_theme
      end,
      set_light_mode = function()
        set_light()
        os.execute("tmux source-file ~/.local/share/fredrik/lazy/nightfox.nvim/extra/dayfox/dayfox.tmux")
        vim.g.lazygit_use_custom_config_file_path = 1
        local light_theme = vim.fs.normalize("$DOTFILES/lazygit_config_light.yml")
        vim.g.lazygit_config_file_path = light_theme
      end,
    },
  },
}
