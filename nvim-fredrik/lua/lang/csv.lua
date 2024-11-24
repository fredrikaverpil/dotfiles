return {
  {
    "hat0uma/csvview.nvim",
    lazy = true,
    ft = { "csv" },
    config = function()
      require("csvview").setup()
    end,
  },
}
