return {
  {
    -- Used as a query provider only. Parsers are managed by Nix.
    -- Queries are loaded from nvim-treesitter's runtime/queries/ via runtimepath.
    -- after/queries/<lang>/*.scm overrides these automatically (loaded last).
    "nvim-treesitter/nvim-treesitter",
    enabled = false,
    lazy = false,
    branch = "main",
    config = function()
      -- Start treesitter for any buffer whose parser is already installed (via Nix).
      -- Silently skips filetypes with no available parser.
      vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function(event)
          local bufnr = event.buf
          local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
          if filetype == "" then
            return
          end
          local lang = vim.treesitter.language.get_lang(filetype)
          if not lang then
            return
          end
          pcall(vim.treesitter.start, bufnr, lang)
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    enabled = false,
    event = "BufRead",
    opts = {
      multiwindow = true,
    },
  },
}
