return {
  {
    "nvim-mini/mini.diff",
    event = "VeryLazy",
    version = "*",
    opts = {
      view = {
        style = "sign",
        signs = {
          add = "▎",
          change = "▎",
          delete = "",
        },
      },
    },
    keys = require("fredrik.config.keymaps").setup_mini_diff_keymaps(),
  },
}
