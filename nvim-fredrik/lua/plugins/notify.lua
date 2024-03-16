return {

  {
    "rcarriga/nvim-notify",
    init = function()
      vim.notify = require("notify")
    end,
  },
}
