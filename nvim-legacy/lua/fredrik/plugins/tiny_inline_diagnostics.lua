return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    opts = {
      options = {
        show_all_diags_on_cursorline = true,
        multilines = {
          enabled = true,
          always_show = true,
        },
        show_source = {
          enabled = true,
        },
      },
    },
    config = function(_, opts)
      require("tiny-inline-diagnostic").setup(opts)
    end,
  },
}
