return {

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    init = function()
      -- TODO: set colorscheme based on system/terminal dark/light mode
      -- Also see utils/colorscheme.lua
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
}
