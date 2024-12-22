return {

  {
    "numToStr/FTerm.nvim",
    lazy = true,
    opts = {
      dimensions = {
        height = 0.9,
        width = 0.9,
      },
    },
    config = function(_, opts)
      require("FTerm").setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_fterm_keymaps(),
  },
}
