return {

  {
    "neovim/nvim-lspconfig",
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
          vim.list_extend(opts.ensure_installed, {
            "graphql-language-service-cli",
          })
        end,
      },
    },
    ft = { "graphql" },
    opts = function(_, opts)
      opts.servers = {
        graphql = {
          -- https://www.npmjs.com/package/graphql-language-service-cli
          settings = {
            graphql = {},
          },
        },
      }
    end,
  },
}
