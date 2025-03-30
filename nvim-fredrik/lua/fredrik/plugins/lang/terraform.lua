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
          vim.list_extend(opts.ensure_installed, { "tflint", "trivy" })
        end,
      },
    },
    opts = {
      linters_by_ft = {
        -- TODO: fix "Module not installed - This module is not yet installed.
        -- Run "tofu init" to install all modules required by this configuration."
        -- NOTE: terraform_validate just runs `terraform validate`.
        terraform = { "terraform_validate", "tflint", "trivy" },
        tf = { "terraform_validate", "tflint", "trivy" },
      },
    },
  },

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
