return {
  {
    "MagicDuck/grug-far.nvim",
    dependencies = {
      {
        "zbirenbaum/copilot.lua",
        opts = {
          filetypes = {

            ["grug-far"] = false,
            ["grug-far-history"] = false,
          },
        },
      },
    },
    opts = {},
    config = function(_, opts)
      require("grug-far").setup(opts)
    end,
    keys = require("config.keymaps").setup_grug_far_keymaps(),
  },
}
