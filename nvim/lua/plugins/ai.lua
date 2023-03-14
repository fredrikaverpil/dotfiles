return {

  -- github copilot
  {
    "github/copilot.vim",
    -- automatically start github copilot
    config = function()
      vim.keymap.set("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
      vim.keymap.set("i", "<C-H>", "copilot#Previous()", { silent = true, expr = true })
      -- vim.keymap.set("i", "<C-K>", 'copilot#Next()', { silent = true, expr = true })
    end,
  },

  -- chatgpt
  {
    "jackMort/ChatGPT.nvim",
    config = function()
      require("chatgpt").setup({
        -- optional configuration
      })
    end,
    dependencies = {
      { "MunifTanjim/nui.nvim" },
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
  },
}
