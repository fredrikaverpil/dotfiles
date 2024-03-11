return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function(_, opts)
      require("neotest").setup(opts)

      require("config.keymaps").setup_neotest_keymaps()
    end,
  },
}
