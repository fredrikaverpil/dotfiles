return {
  {
    "andythigpen/nvim-coverage",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function(_, opts)
      require("coverage").setup(opts)
      require("config.keymaps").setup_coverage_keymaps()
    end,
  },
}
