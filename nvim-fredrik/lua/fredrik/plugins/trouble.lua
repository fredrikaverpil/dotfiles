return {
  {
    "folke/trouble.nvim",
    lazy = true,
    dependencies = {
      -- icons supported via mini-icons.lua
    },
    opts = {},
    keys = require("fredrik.config.keymaps").setup_trouble_keymaps(),
  },
}
