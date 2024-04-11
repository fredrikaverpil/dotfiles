return {
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    branch = "dev", -- v3
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    keys = require("config.keymaps").setup_trouble_keymaps(),
  },
}
