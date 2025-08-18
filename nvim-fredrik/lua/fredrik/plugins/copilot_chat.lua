return {

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = false,
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
      selection = function(source)
        if require("fredrik.utils.private").is_code_public() then
          local select = require("CopilotChat.select")
          return select.visual(source) or select.buffer(source)
        else
          return nil
        end
      end,
      -- model = "claude-3.7-sonnet", -- NOTE: requires paid subscription
      prompts = require("fredrik.utils.llm_prompts").to_copilot(),
    },
    keys = function()
      return require("fredrik.config.keymaps").setup_copilot_chat_keymaps()
    end,
  },
}
