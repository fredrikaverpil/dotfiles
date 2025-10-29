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

      -- override the diagnostics settings (see diagnostics.lua)
      local diagnostics_opts = vim.diagnostic.config()
      diagnostics_opts.enable = false
      diagnostics_opts.virtual_lines = false
      diagnostics_opts.virtual_text = false
      vim.diagnostic.config(diagnostics_opts)
    end,
  },
}
