return {

  {
    "numToStr/FTerm.nvim",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      require("FTerm").setup(opts)
      require("config.keymaps").setup_terminal_keymaps()
    end,
  },
}
