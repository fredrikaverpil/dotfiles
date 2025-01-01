return {

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
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
          vim.list_extend(opts.ensure_installed, { "tflint", "tfsec" })
        end,
      },
    },
    opts = {
      linters_by_ft = {
        terraform = { "terraform_validate", "tflint", "tfsec" },
        tf = { "terraform_validate", "tflint", "tfsec" },
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
          vim.list_extend(opts.ensure_installed, { "terraformls" })
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        terraformls = {
          -- lsp: https://github.com/hashicorp/terraform-ls
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/terraformls.lua
          cmd = { "terraform-ls", "serve" },
          filetypes = { "terraform", "tf", "terraform-vars" },
          root_markers = { ".terraform", "terraform" },
          settings = {
            terraformls = {},
          },
        },
      },
    },
  },
}
