vim.notify = require("notify")

return {

  {
    "rcarriga/nvim-notify",
    lazy = false,
    priority = 900,
    init = function(_, opts)
      require("notify").setup(opts)
    end,
  },
}
