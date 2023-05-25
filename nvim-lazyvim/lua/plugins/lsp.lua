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
        "pyright",
        -- "debugpy",
        -- "mypy",

        -- lua
        "lua-language-server",
        "stylua",

        -- shell
        "shellcheck",
        "shfmt",

        -- docker
        "dockerfile-language-server",

        -- javascript/typescript
        "prettierd",
        "typescript-language-server",
        "eslint-lsp",

        -- rust
        "rustfmt",
        "rust-analyzer",
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

      null_ls.setup({
        -- debug = true, -- Turn on debug for :NullLsLog
        debug = false,
        -- diagnostics_format = "#{m} #{s}[#{c}]",
        sources = {
          -- list of supported sources:
          -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

          -- get from $PATH
          diagnostics.ruff,
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
          formatting.prettierd.with({
            command = mason_registry.get_package("prettierd").path,
          }),
          formatting.rustfmt.with({
            command = mason_registry.get_package("rustfmt").path,
          }),
          code_actions.shellcheck.with({
            command = mason_registry.get_package("shellcheck").path,
          }),
        },
      })
    end,
  },
}
