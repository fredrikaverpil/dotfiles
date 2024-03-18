return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    enabled = false,
    config = function(_, opts)
      require("toggleterm").setup(opts)

      require("config.keymaps").setup_terminal_keymaps()
    end,
  },
}
