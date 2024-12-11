return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      notifier = { enabled = true, timeout = 2000 },
      lazygit = {
        -- automatically configure lazygit to use the current colorscheme
        -- and integrate edit with the current neovim instance
        configure = true,
      },
    },
    keys = require("fredrik.config.keymaps").setup_snacks_keymaps(),
  },
}
