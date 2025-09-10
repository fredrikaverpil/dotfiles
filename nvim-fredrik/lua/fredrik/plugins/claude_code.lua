return {
  {
    "greggh/claude-code.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("claude-code").setup()
    end,
    keys = require("fredrik.config.keymaps").setup_claudecode_keymaps(),
  },
}
