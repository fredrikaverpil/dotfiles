return {

  {
    "kdheepak/lazygit.nvim",
    enabled = false,
    lazy = true,
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = require("fredrik.config.keymaps").setup_lazygit_keymaps(),
  },
}
