return {
  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline", "OutlineOpen" },
    opts = {
      auto_jump = true,
      center_on_jump = true,
    },
    keys = require("config.keymaps").setup_outline_keymaps(),
  },
}
