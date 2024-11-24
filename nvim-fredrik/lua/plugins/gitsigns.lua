return {
  {
    "lewis6991/gitsigns.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {
      on_attach = function(bufnr)
        require("config.keymaps").setup_gitsigns_keymaps(bufnr)
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
    end,
  },
}
