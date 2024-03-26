return {
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    config = function()
      require("config.keymaps").setup_fugitive_keymaps()
    end,
  },
}
