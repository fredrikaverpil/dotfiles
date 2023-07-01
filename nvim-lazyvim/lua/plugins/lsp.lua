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

        -- lua
        "lua-language-server",
        "stylua",

        -- shell
        "bash-language-server",
        "shellcheck",
        "shfmt",

        -- docker
        "dockerfile-language-server",

        -- javascript/typescript, see lazy.lua

        -- rust, also see lazy.lua
        "rust-analyzer", -- LSP
        "rustfmt",

        -- go, see lazy.lua
      },
    },
  },

  -- change null-ls config
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "mason.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = function(_, opts)
      local mason_registry = require("mason-registry")
      mason_registry.refresh()

      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics
      local code_actions = null_ls.builtins.code_actions

      -- null_ls.setup({
      --   debug = false, -- Turn on debug for :NullLsLog
      --   -- diagnostics_format = "#{m} #{s}[#{c}]",
      -- })

      local sources = {
        -- list of supported sources:
        -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md

        -- not installed via Mason, expected to be found on $PATH
        diagnostics.mypy,
        formatting.black,

        -- installed via Mason
        formatting.stylua.with({
          extra_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        }),
        formatting.shfmt,
        formatting.rustfmt,
        formatting.yamlfix, -- requires python
        diagnostics.yamllint,
        diagnostics.shellcheck,
        code_actions.shellcheck,
        code_actions.gitsigns,
      }

      -- extend opts.sources
      for _, source in ipairs(sources) do
        table.insert(opts.sources, source)
      end
    end,
  },
}
