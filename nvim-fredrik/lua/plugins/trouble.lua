return {
  {
    "folke/trouble.nvim",
    lazy = true,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    keys = require("config.keymaps").setup_trouble_keymaps(),
  },
}
