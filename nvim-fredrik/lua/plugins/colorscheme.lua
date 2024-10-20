local function set_dark()
  vim.cmd.colorscheme("tokyonight-moon")
end

local function set_light()
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
        if tmux_is_running() then
          os.execute("tmux source-file ~/.tmux/plugins/tokyonight.nvim/extras/tmux/tokyonight_moon.tmux")
        end
        vim.g.lazygit_use_custom_config_file_path = 1
        local dark_theme = vim.fs.normalize("$DOTFILES/lazygit_config_dark.yml")
        vim.g.lazygit_config_file_path = dark_theme
      end,
      set_light_mode = function()
        set_light()
        if tmux_is_running() then
          os.execute("tmux source-file ~/.local/share/fredrik/lazy/nightfox.nvim/extra/dayfox/dayfox.tmux")
        end
        vim.g.lazygit_use_custom_config_file_path = 1
        local light_theme = vim.fs.normalize("$DOTFILES/lazygit_config_light.yml")
        vim.g.lazygit_config_file_path = light_theme
      end,
    },
  },
}
