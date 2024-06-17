return {

  {
    "nvim-pack/nvim-spectre",
    enabled = false, -- use grug-far instead
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-tree/nvim-web-devicons" },
    },

    config = function()
      require("spectre").setup()
      require("config.keymaps").setup_spectre_keymaps()
    end,
  },
}
