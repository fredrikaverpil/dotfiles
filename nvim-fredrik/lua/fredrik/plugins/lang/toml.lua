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
          vim.list_extend(opts.ensure_installed, { "taplo" })
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        taplo = {
          -- lsp: https://taplo.tamasfe.dev/cli/usage/language-server.html
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/taplo.lua
          cmd = { "taplo", "lsp", "stdio" },
          filetypes = { "toml" },
          root_markers = { ".git" },
          settings = {
            taplo = {},
          },
        },
      },
    },
  },
}
