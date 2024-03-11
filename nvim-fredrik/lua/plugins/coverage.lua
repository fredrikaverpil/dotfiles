return {
  {
    "andythigpen/nvim-coverage",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("coverage").setup()
      require("config.keymaps").setup_coverage_keymaps()
    end,
  },
}
