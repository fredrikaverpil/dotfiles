return {

  -- change trouble config
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = {
      -- auto_open = false, -- automatically open the list when you have diagnostics
      -- auto_close = false, -- automatically close the list when you have no diagnostics
      -- use_diagnostic_signs = true, -- enabling this will use the signs defined in your lsp client
      -- auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
    },
  },

  -- change null-ls config
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local diagnostics = null_ls.builtins.diagnostics

      null_ls.setup({
        -- debug = true, -- Turn on debug for :NullLsLog
        debug = false,
        diagnostics_format = "#{m} #{s}[#{c}]",
        sources = {
          -- list of supported sources:
          -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
          diagnostics.ruff,
          diagnostics.mypy,
        },
      })
    end,
  },
}
