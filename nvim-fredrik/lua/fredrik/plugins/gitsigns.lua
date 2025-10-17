return {
  {
    "lewis6991/gitsigns.nvim",
    enabled = false, -- I'm evaluating mini.diff instead...
    event = "VeryLazy",
    opts = {
      on_attach = function(bufnr)
        require("fredrik.config.keymaps").setup_gitsigns_keymaps(bufnr)
      end,
    },
    config = function(_, opts)
      require("gitsigns").setup(opts)
    end,
  },
}
