return {

  {
    "numToStr/FTerm.nvim",
    event = "VimEnter",
    config = function()
      require("config.keymaps").setup_terminal_keymaps()
    end,
  },
}
