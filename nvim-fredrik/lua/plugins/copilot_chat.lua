return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    event = "VeryLazy",
    enabled = require("utils.private").enable_copilot(),
    branch = "canary", -- while in development
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      debug = false, -- Enable debugging
    },
  },
}
