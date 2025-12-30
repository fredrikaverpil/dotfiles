return {
  {
    "nvim-mini/mini.nvim",
    version = "*",
    opts = {},
    config = function(_, opts)
      require("mini.cmdline").setup(opts)
    end,
  },
}
