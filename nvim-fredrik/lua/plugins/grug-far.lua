return {
  {
    "MagicDuck/grug-far.nvim",
    opts = {},
    config = function(_, opts)
      require("grug-far").setup(opts)
    end,
    keys = require("config.keymaps").setup_grug_far_keymaps(),
  },
}
