return {
  {
    "stevearc/conform.nvim",
    config = function(_, opts)
      require("conform").setup({
        formatters_by_ft = opts.formatters_by_ft,
      })
    end,
  },
}
