return {

  {
    "rcarriga/nvim-notify",
    lazy = true,
    event = "VeryLazy",
    enabled = false, -- NOTE: using snacks.nvim instead
    -- priority = 900,
    config = function(_, opts)
      vim.notify = require("notify")
      require("notify").setup(opts)
    end,
  },
}
