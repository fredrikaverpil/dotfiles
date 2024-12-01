return {
  {
    -- https://github.com/folke/which-key.nvim
    "folke/which-key.nvim",
    lazy = true,
    event = "VeryLazy",
    dependencies = {
      "echasnovski/mini.icons",
    },
    opts = {},
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      require("fredrik.config.keymaps").setup_whichkey()
    end,
    keys = require("fredrik.config.keymaps").setup_whichkey_contextual(),
  },
}
