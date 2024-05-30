return {

  {
    "gbprod/yanky.nvim",
    event = "VeryLazy",
    opts = function()
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below

      require("config.keymaps").setup_yanky_keymaps()
    end,
  },
}
