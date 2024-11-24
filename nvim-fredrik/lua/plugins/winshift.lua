return {
  {
    "sindrets/winshift.nvim",
    lazy = true,
    keys = require("config.keymaps").setup_winshift_keymaps(),
    cmd = { "WinShift" },
  },
}
