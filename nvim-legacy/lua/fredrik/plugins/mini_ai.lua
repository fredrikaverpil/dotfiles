return {

  {
    "echasnovski/mini.ai",
    lazy = true,
    event = "BufReadPost",
    version = "*",
    opts = {},
    config = function(_, opts)
      require("mini.ai").setup(opts)
    end,
  },
}
