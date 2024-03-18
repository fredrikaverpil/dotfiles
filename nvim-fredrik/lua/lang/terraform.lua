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
        terraformls = {},
      },
    },
  },

  -- {
  --    "nvim-telescope/telescope.nvim",
  --    dependencies = {
  --      {
  --        "ANGkeith/telescope-terraform-doc.nvim",
  --        config = function()
  --          Util.on_load("telescope.nvim", function()
  --            require("telescope").load_extension("terraform_doc")
  --          end)
  --        end,
  --      },
  --      {
  --        "cappyzawa/telescope-terraform.nvim",
  --        config = function()
  --          Util.on_load("telescope.nvim", function()
  --            require("telescope").load_extension("terraform")
  --          end)
  --        end,
  --      },
  --    },
  --  },
}
