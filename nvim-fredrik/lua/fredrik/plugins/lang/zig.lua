return {

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    ft = { "zig" },
    opts = {
      ensure_installed = { "zig" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    lazy = true,
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
          vim.list_extend(opts.ensure_installed, { "zls" })
        end,
      },
    },
    opts = {
      servers = {
        zls = {
          filetypes = { "zig" },
          settings = {
            zls = {},
          },
        },
      },
    },
  },

  {
    "nvim-neotest/neotest",
    lazy = true,
    ft = { "zig" },
    dependencies = {
      {
        "lawrence-laz/neotest-zig",
        version = "*",
      },
    },
    opts = {
      adapters = {
        ["neotest-zig"] = {
          dap = {
            adapter = "lldb",
          },
        },
      },
    },
  },

  {
    "CRAG666/code_runner.nvim",
    lazy = true,
    opts = {
      filetype = {
        zig = {
          "zig run",
        },
      },
    },
  },
}
