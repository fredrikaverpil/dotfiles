-- https://www.lazyvim.org/plugins/lsp
-- NOTE: don't forget to update treesitter for languages
-- NOTE: see lazy.lua for extras that configure LSPs, formatters, linters and code actions.

return {

  {
    "williamboman/mason.nvim",

    opts = function(_, opts)
      local ensure_installed = {
        -- python
        "ruff-lsp", -- lsp
        "pyright", -- lsp
        "black", -- formatter
        "mypy", -- linter

        -- lua
        "lua-language-server", -- lsp
        "stylua", -- formatter

        -- shell
        "bash-language-server", -- lsp
        "shfmt", -- formatter
        "shellcheck", -- linter

        -- yaml
        "yamllint", -- linter

        -- sql
        "sqlfluff", -- linter

        -- rust
        "rust-analyzer", -- lsp
        -- rustfmt -- formatter (install via rustup)

        -- go
        -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md
        -- https://github.com/golang/tools/blob/master/gopls/internal/lsp/source/options.go
        "gopls", -- lsp
        "golangci-lint-langserver", -- lsp
        "gofumpt", -- formatter
        "goimports", -- formatter
        "golangci-lint", -- linter (required by golanci-lint-langserver?)
        "gomodifytags", -- code actions
        "impl", -- code actions

        -- protobuf
        "buf-language-server", -- lsp (prototype, not feature-complete yet, rely on buf for now)
        "buf", -- formatter, linter
        "protolint", -- linter
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)
    end,
  },

  {
    "nvimtools/none-ls.nvim",
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      local function prefer_bin_from_venv(executable_name)
        -- Return the path to the executable if $VIRTUAL_ENV is set and the binary exists somewhere beneath the $VIRTUAL_ENV path, otherwise get it from Mason
        if vim.env.VIRTUAL_ENV then
          local paths = vim.fn.glob(vim.env.VIRTUAL_ENV .. "/**/bin/" .. executable_name, true, true)
          local executable_path = table.concat(paths, ", ")
          if executable_path ~= "" then
            return executable_path
          end
        end

        local mason_registry = require("mason-registry")
        local mason_path = mason_registry.get_package(executable_name):get_install_path()
          .. "/venv/bin/"
          .. executable_name
        return mason_path
      end

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
      local remove_from_sources = {
        "goimports_reviser",
      }
      for _, source in ipairs(remove_from_sources) do
        for i, v in ipairs(opts.sources) do
          if v.name == source then
            table.remove(opts.sources, i)
          end
        end
      end
    end,
  },
}
