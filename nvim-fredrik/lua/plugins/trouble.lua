return {
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    keys = require("config.keymaps").setup_trouble_keymaps(),
  },
}
