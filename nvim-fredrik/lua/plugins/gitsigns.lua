return {
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()

      require("config.keymaps").setup_gitsigns_keymaps()
    end,
  },
}
