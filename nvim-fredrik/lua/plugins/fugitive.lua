return {
  {
    "tpope/vim-fugitive",
    config = function()
      require("config.keymaps").setup_fugitive_keymaps()
    end,
  },
}
