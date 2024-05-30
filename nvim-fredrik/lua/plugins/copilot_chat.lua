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
    config = function(_, opts)
      require("CopilotChat").setup(opts)
      require("CopilotChat.integrations.cmp").setup()
    end,
    keys = require("config.keymaps").setup_copilot_chat_keymaps(),
  },
}
