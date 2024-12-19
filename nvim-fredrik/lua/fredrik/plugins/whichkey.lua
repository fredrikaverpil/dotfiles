return {
  {
    -- https://github.com/folke/which-key.nvim
    "folke/which-key.nvim",
    lazy = true,
    event = "VeryLazy",
    dependencies = {
      "echasnovski/mini.icons",
    },
    opts = {
      preset = "helix",
    },
    config = function(_, opts)
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      local wk = require("which-key")
      require("fredrik.config.keymaps").setup_whichkey(wk)
      wk.setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_whichkey_contextual(),
  },
}
