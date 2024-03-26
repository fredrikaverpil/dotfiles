return {

  {
    "numToStr/FTerm.nvim",
    event = "VeryLazy",
    config = function()
      require("config.keymaps").setup_terminal_keymaps()
    end,
  },
}
