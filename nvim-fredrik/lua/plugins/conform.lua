return {
  {
    -- https://github.com/stevearc/conform.nvim
    "stevearc/conform.nvim",
    config = function(_, opts)
      -- TODO: add toggle keymap for aut-save on/off by leveraging a vim.g variable and:
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        callback = function(args)
          if vim.g.auto_format then
            require("conform").format({
              bufnr = args.buf,
              timeout_ms = 500,
              lsp_fallback = true,
            })
          else
          end
        end,
      })

      -- set initial state to auto-format
      vim.g.auto_format = true

      -- Auto-formatting disabled, so that it can instead be handled by the autocmd. To enable, uncomment the below.
      -- opts.format_on_save = {
      --   -- These options will be passed to conform.format()
      --   timeout_ms = 500,
      --   lsp_fallback = true,
      -- }
      require("conform").setup(opts)
      require("config.keymaps").setup_conform_keymaps()
    end,
  },
}
