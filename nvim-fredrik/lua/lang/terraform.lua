return {

  {
    "stevearc/conform.nvim",
    lazy = true,
    ft = { "terraform", "tf", "terraform-vars" },
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
    lazy = true,
    ft = { "terraform", "tf", "terraform-vars" },
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
    lazy = true,
    -- ft = { "terraform", "tf", "terraform-vars" },
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
        terraformls = {
          filetypes = { "terraform", "tf", "terraform-vars" },
        },
      },
    },
  },
}
