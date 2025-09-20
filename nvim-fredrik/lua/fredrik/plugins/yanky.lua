return {

  {
    "gbprod/yanky.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    lazy = true,
    opts = {},
    keys = require("fredrik.config.keymaps").setup_yanky_keymaps(),
  },
}
