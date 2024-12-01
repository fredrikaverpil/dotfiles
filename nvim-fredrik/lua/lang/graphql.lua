return {

  {
    "neovim/nvim-lspconfig",
    lazy = true,
    -- ft = { "graphql" },
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
            "graphql",
          })
        end,
      },
    },
    opts = {
      servers = {
        graphql = {
          -- https://www.npmjs.com/package/graphql-language-service-cli
          filetypes = { "graphql" },
          settings = {
            graphql = {},
          },
        },
      },
    },
  },
}
