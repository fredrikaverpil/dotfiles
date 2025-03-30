return {

  {
    "virtual-lsp-config",
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
        ---@type vim.lsp.Config
        graphql = {
          -- cli: https://github.com/graphql/graphiql/blob/main/packages/graphql-language-service-server/README.md
          -- lsp: https://www.npmjs.com/package/graphql-language-service-cli
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/graphql.lua
          cmd = { "graphql-lsp", "server", "-m", "stream" },
          filetypes = { "graphql" },
          root_markers = { ".graphqlrc", ".graphql.config", "graphql.config" },
          settings = {
            graphql = {},
          },
        },
      },
    },
  },
}
