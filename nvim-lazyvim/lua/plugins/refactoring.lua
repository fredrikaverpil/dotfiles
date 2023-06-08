return {

  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },
    { "nvim-treesitter/nvim-treesitter" },
  },
  config = function()
    require("refactoring").setup()
  end,
  keys = {
    {
      "<leader>cR",
      ":lua require('refactoring').select_refactor()<CR>",
      mode = "v",
      desc = "Refactor",
    },
  },
}
