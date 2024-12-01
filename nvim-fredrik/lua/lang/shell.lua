return {

  {
    "stevearc/conform.nvim",
    lazy = true,
    ft = { "sh" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "shfmt" })
        end,
      },
    },
    opts = {
      formatters_by_ft = {
        sh = { "shfmt" },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    lazy = true,
    ft = { "sh" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "shellcheck" })
        end,
      },
    },
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    lazy = true,
    -- ft = { "sh" },
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
          {
            "williamboman/mason.nvim",
          },
        },
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "bashls" })
        end,
      },
    },
    opts = {
      servers = {
        -- https://github.com/bash-lsp/bash-language-server
        bashls = {
          filetypes = { "sh" },
        },
      },
    },
  },
}
