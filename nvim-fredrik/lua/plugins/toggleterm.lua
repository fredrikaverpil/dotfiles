return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function(_, opts)
      require("toggleterm").setup(opts)

      require("config.keymaps").setup_toggleterm_keymaps()
    end,
  },
}
