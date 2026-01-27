return {
  {
    "nvim-mini/mini.diff",
    lazy = false, -- without this, it won't always load on startup... weird.
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
