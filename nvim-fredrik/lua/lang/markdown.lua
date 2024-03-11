return {

  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "markdownlint" })
        end,
      },
    },
    ft = { "markdown" },
    opts = {
      formatters_by_ft = {
        markdown = { "markdownlint" },
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "markdownlint" })
        end,
      },
    },
    ft = { "markdown" },
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint" },
      },
    },
  },
}
