return {

  {
    "gbprod/yanky.nvim",
    lazy = true,
    event = "BufReadPost",
    keys = require("config.keymaps").setup_yanky_keymaps(),
  },
}
