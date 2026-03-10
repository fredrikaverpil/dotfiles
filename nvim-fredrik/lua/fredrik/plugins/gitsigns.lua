return {
  {
    "lewis6991/gitsigns.nvim",
    -- enabled = false, -- I'm evaluating mini.diff instead...
    version = false,
    event = "VeryLazy",
    keys = require("fredrik.config.keymaps").setup_gitsigns_keymaps(),
    opts = {},
  },
}
