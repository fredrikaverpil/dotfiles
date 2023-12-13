return {
  {

    "nvimtools/none-ls.nvim",
    enabled = false, -- this is old, see lsp.lua instead
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      local sources = {
        -- list of supported sources:
        -- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md

        -- python
        formatting.black.with({
          filetypes = { "python" },
          command = prefer_bin_from_venv("black"),
        }),
        diagnostics.mypy.with({
          filetypes = { "python" },
          command = prefer_bin_from_venv("mypy"),
        }),

        -- lua
        formatting.stylua.with({
          extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        }),

        -- shell
        formatting.shfmt,
        diagnostics.shellcheck,
        code_actions.shellcheck,

        -- yaml
        diagnostics.yamllint,

        -- sql
        diagnostics.sqlfluff.with({
          extra_args = { "--dialect", "postgres" },
        }),

        -- rust
        formatting.rustfmt,

        -- go
        formatting.gofumpt,
        formatting.goimports,
        -- diagnostics.golangci_lint, (likely not needed... as golangci-lint-langserver is used?)
        code_actions.gomodifytags,
        code_actions.impl,

        -- protobuf
        formatting.buf,
        diagnostics.buf,
        diagnostics.protolint,
      }

      -- extend opts.sources
      for _, source in ipairs(sources) do
        table.insert(opts.sources, source)
      end

      -- always remove from opts.sources (e.g. added by lazy.lua extras)
      local remove_sources = { "goimports_reviser" }
      opts.sources = vim.tbl_filter(function(source)
        return not vim.tbl_contains(remove_sources, source.name)
      end, opts.sources)
    end,
  },
}
