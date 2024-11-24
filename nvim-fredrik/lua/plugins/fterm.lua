return {

  {
    "numToStr/FTerm.nvim",
    lazy = true,
    opts = {},
    config = function(_, opts)
      require("FTerm").setup(opts)
    end,
    keys = require("config.keymaps").setup_terminal_keymaps(),
  },
}
