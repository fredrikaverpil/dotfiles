return {
  {
    -- https://github.com/stevearc/conform.nvim
    "stevearc/conform.nvim",
    lazy = true,
    event = "BufWritePre",
    config = function(_, opts)
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
