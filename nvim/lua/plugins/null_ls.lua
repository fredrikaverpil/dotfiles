return {

  -- change null-ls config
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics

      null_ls.setup({
        -- debug = true, -- Turn on debug for :NullLsLog
        debug = false,
        diagnostics_format = "#{m} #{s}[#{c}]",
        sources = {
          -- list of supported sources:
          -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
          formatting.stylua,
          formatting.black, -- causes crash on multiple file save with neovim 0.8.3
          diagnostics.ruff,
          diagnostics.mypy,
        },
      })
    end,
  },
}
