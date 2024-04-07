return {

  {
    "mfussenegger/nvim-lint",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "hadolint" })
        end,
      },
    },
    ft = { "dockerfile" },
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
          vim.list_extend(opts.ensure_installed, {
            "dockerfile-language-server",
            -- "docker-compose-language-service",
          })
        end,
      },
    },
    ft = {
      "dockerfile",
      -- "yaml",
    },
    opts = {
      servers = {
        -- https://github.com/rcjsuen/dockerfile-language-server
        dockerls = {},

        -- TODO: investigate why this client won't attach
        -- docker_compose_language_service = {},
      },
    },
  },
}
