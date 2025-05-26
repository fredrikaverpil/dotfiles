return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        csv = { "csv" },
      },
    },
  },

  {
    "hat0uma/csvview.nvim",
    lazy = true,
    ft = { "csv" },
    config = function()
      require("csvview").setup()
    end,
  },
}
