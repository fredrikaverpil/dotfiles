return {

  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = true,
    lazy = true,
    event = "VeryLazy",
    version = "*",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    opts = {
      selection = function(source)
        -- if require("fredrik.utils.private").is_code_public() then
        --   local select = require("CopilotChat.select")
        --   return select.visual(source) or select.buffer(source)
        -- else
        --   return nil
        -- end

        return nil -- just disable selection
      end,
    },
    keys = function()
      return require("fredrik.config.keymaps").setup_copilot_chat_keymaps()
    end,
  },
}
