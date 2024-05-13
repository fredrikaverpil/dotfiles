return {
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    branch = "dev", -- v3
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
    keys = require("config.keymaps").setup_trouble_keymaps(),
  },
}
