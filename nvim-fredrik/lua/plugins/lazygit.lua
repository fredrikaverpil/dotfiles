return {

  {
    "kdheepak/lazygit.nvim",
    -- optional for floating window border decoration
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("utils.keymaps").setup_lazygit_keymaps()
    end,
  },
}
