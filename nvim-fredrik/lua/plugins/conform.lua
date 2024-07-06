return {
  {
    -- https://github.com/stevearc/conform.nvim
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function(_, opts)
      -- TODO: add toggle keymap for auto-save on/off by leveraging a vim.g variable and:
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        callback = function(args)
          if vim.g.auto_format then
            require("conform").format({
              bufnr = args.buf,
              timeout_ms = 5000,
              lsp_format = "fallback",
            })
          else
          end
        end,
      })

      -- set initial state to auto-format
      vim.g.auto_format = true

      require("conform").setup(opts)
      require("config.keymaps").setup_conform_keymaps()
    end,
  },
}
