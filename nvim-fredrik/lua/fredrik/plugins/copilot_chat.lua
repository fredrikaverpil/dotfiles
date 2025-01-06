return {

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = true,
    event = "VeryLazy",
    version = "*",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    ---@type CopilotChat.config
    opts = {
      debug = false, -- Enable debugging
      model = "claude-3.5-sonnet",
    },
    keys = function()
      local chat = require("CopilotChat")
      return require("fredrik.config.keymaps").setup_copilot_chat_keymaps(chat)
    end,
  },
}
