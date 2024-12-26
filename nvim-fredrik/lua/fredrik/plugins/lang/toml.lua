return {

  {
    "stevearc/conform.nvim",
    lazy = true,
    ft = { "toml" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "taplo" })
        end,
      },
    },
    opts = {
      formatters_by_ft = {
        toml = { "taplo" },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    lazy = true,
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
          vim.list_extend(opts.ensure_installed, { "taplo" })
        end,
      },
    },
    opts = {
      servers = {
        taplo = {
          filetypes = { "toml" },
          settings = {
            taplo = {},
          },
        },
      },
    },
  },
}
