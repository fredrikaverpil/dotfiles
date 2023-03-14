return {

  -- NOTE: see null_ls.lua for diagnostics config via null-ls

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
}
