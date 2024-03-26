return {

  {
    "kdheepak/lazygit.nvim",
    event = "VeryLazy",
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("config.keymaps").setup_lazygit_keymaps()
    end,
  },
}
