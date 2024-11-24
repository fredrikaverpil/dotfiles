return {

  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = require("config.keymaps").setup_lazygit_keymaps(),
  },
}
