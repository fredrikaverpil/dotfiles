return {
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    branch = "dev", -- v3
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      {
        "nvim-telescope/telescope.nvim",
        opts = function(_, opts)
          return require("config.keymaps").setup_trouble_telescope_keymaps(opts)
        end,
      },
    },
    opts = {},
    keys = require("config.keymaps").setup_trouble_keymaps(),
  },
}
