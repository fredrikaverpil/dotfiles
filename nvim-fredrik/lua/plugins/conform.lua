return {
  {
    -- https://github.com/stevearc/conform.nvim
    "stevearc/conform.nvim",
    config = function(_, opts)
      -- TODO: add toggle keymap for aut-save on/off by leveraging a vim.g variable and:
      -- vim.api.nvim_create_autocmd("BufWritePre", {
      --   pattern = "*",
      --   callback = function(args)
      --     -- read global variable here...
      --     require("conform").format({ bufnr = args.buf })
      --   end,
      -- })

      opts.format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 500,
        lsp_fallback = true,
      }

      require("conform").setup(opts)
    end,
  },
}
