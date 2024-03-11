return {

  {
    "nvim-pack/nvim-spectre",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-tree/nvim-web-devicons" },
    },

    config = function()
      require("spectre").setup()
      require("utils.keymaps").setup_spectre_keymaps()
    end,
  },
}
