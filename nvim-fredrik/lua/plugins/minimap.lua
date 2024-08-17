return {
  {
    "Isrothy/neominimap.nvim",
    enabled = true,
    lazy = true,
    keys = require("config.keymaps").setup_minimap_keymaps(),
  },
}
