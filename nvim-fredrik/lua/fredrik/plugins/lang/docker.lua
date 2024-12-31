return {

  {
    "mfussenegger/nvim-lint",
    lazy = true,
    ft = { "dockerfile" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "hadolint" })
        end,
      },
    },
    opts = {
      linters_by_ft = {
        dockerfile = { "hadolint" },
      },
    },
  },

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
          vim.list_extend(opts.ensure_installed, { "dockerls" })
        end,
      },
    },
    opts = {
      servers = {
        -- lsp: https://github.com/rcjsuen/dockerfile-language-server
        -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/dockerls.lua
        ---@type vim.lsp.Config
        dockerls = {
          cmd = { "docker-langserver", "--stdio" },
          filetypes = { "dockerfile" },
          root_markers = { "Dockerfile" },
          settings = {
            docker = {},
          },
        },
      },
    },
  },
}
