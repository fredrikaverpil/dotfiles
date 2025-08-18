return {

  {
    "NickvanDyke/opencode.nvim",
    dependencies = { "folke/snacks.nvim" },
    ---@type opencode.Config
    opts = {
      -- Your configuration, if any
    },
  -- stylua: ignore
  keys = require("fredrik.config.keymaps").setup_opencode_keymaps(),
  },
}
