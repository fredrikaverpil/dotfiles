return {
  {
    "folke/trouble.nvim",
    lazy = true,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        "nvim-lualine/lualine.nvim",
        opts = {
          extensions = { "trouble" },
        },
      },
    },
    opts = {},
    keys = require("fredrik.config.keymaps").setup_trouble_keymaps(),
  },
}
