return {
  {
    "Isrothy/neominimap.nvim",
    lazy = true,
    enabled = true,
    keys = require("config.keymaps").setup_minimap_keymaps(),
  },
}
