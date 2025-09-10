return {
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      window = {
        position = "vertical",
      },
    },
    keys = require("fredrik.config.keymaps").setup_claudecode_keymaps(),
  },
}
