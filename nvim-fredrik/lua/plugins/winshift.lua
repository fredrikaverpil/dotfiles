return {
  {
    "sindrets/winshift.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("winshift").setup(opts)
      require("config.keymaps").setup_winshift_keymaps()
    end,
  },
}
