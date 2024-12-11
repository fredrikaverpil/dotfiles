return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      -- visuals
      notifier = { enabled = true, timeout = 2000 },
      statuscolumn = { enabled = true },
      indent = { enabled = true },

      -- special mode
      -- dim = { enabled = true },
      zen = { enabled = true },

      -- convenience
      quickfile = { enabled = true },

      -- integrations
      lazygit = {
        enabled = true,
        -- automatically configure lazygit to use the current colorscheme
        -- and integrate edit with the current neovim instance
        configure = true,
      },
    },
    keys = require("fredrik.config.keymaps").setup_snacks_keymaps(),
  },
}
