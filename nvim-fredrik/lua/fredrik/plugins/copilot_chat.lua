return {

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    lazy = true,
    event = "VeryLazy",

    -- version = "*",
    -- version = "v3.10.0", -- NOTE: bad
    -- commit = "cf02033", -- NOTE: bad; breaks test detection in neotest
    version = "v3.9.1", -- NOTE: ok

    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    ---@type CopilotChat.config
    opts = {
      debug = false, -- Enable debugging
      selection = function(source)
        local select = require("CopilotChat.select")
        if require("fredrik.utils.private").is_ai_enabled() then
          return select.visual(source) or select.buffer(source)
        else
          return nil
        end
      end,
      model = "claude-3.7-sonnet",
      prompts = require("fredrik.utils.llm_prompts").to_copilot(),
    },
    keys = function()
      local chat = require("CopilotChat")
      return require("fredrik.config.keymaps").setup_copilot_chat_keymaps(chat)
    end,
  },
}
