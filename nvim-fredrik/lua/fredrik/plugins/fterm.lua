return {

  {
    "numToStr/FTerm.nvim",
    lazy = true,
    opts = {},
    config = function(_, opts)
      require("FTerm").setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_terminal_keymaps(),
  },
}
