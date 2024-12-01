return {
  {
    "sindrets/winshift.nvim",
    lazy = true,
    keys = require("fredrik.config.keymaps").setup_winshift_keymaps(),
    cmd = { "WinShift" },
  },
}
