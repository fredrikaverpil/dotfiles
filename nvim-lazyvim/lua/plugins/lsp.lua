-- https://www.lazyvim.org/plugins/lsp

return {

  -- change mason config
  -- note: don't forget to update treesitter for languages
  {
    "williamboman/mason.nvim",
    -- opts will be merged with the parent spec
    opts = {
      ensure_installed = {
        -- python
        "ruff-lsp",
        "pyright",
        -- "debugpy",
        -- "mypy",

        -- lua
        "lua-language-server",
        "stylua",

        -- shell
        "bash-language-server",
        "shellcheck",
        "shfmt",

        -- docker
        "dockerfile-language-server",

        -- javascript/typescript
        "prettierd",
        "typescript-language-server",
        "eslint_d",

        -- rust
        "rustfmt",
        "rust-analyzer",

        -- go
        -- handled by lazy.lua
      },
    },
  },

  -- change null-ls config
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      local mason_registry = require("mason-registry")
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      mason_registry.refresh()

      null_ls.setup({
        debug = false, -- Turn on debug for :NullLsLog
        -- diagnostics_format = "#{m} #{s}[#{c}]",
        sources = {
          -- list of supported sources:
          -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

          -- get from $PATH
          -- diagnostics.ruff,
          diagnostics.mypy,
          formatting.black,

          -- get from mason
          formatting.stylua.with({
            command = mason_registry.get_package("stylua").path,
            extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
          }),
          formatting.shfmt.with({
            command = mason_registry.get_package("shfmt").path,
          }),
          -- diagnostics.eslint_d.with({
          --   command = mason_registry.get_package("eslint_d").path,
          -- }),
          formatting.prettierd.with({
            command = mason_registry.get_package("prettierd").path,
          }),
          formatting.rustfmt.with({
            command = mason_registry.get_package("rustfmt").path,
          }),
          -- formatting.yamlfmt.with({
          --   command = mason_registry.get_package("yamlfmt").path,
          -- }),
          formatting.yamlfix.with({
            command = mason_registry.get_package("yamlfix").path, -- requires python
          }),

          diagnostics.yamllint.with({
            command = mason_registry.get_package("yamllint").path,
          }),
          diagnostics.shellcheck.with({
            command = mason_registry.get_package("shellcheck").path,
          }),

          code_actions.shellcheck.with({
            command = mason_registry.get_package("shellcheck").path,
          }),
          code_actions.gitsigns,
        },
      })
    end,
  },
}
