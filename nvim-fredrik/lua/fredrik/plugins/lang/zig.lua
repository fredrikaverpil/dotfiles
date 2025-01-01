return {

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "zig" },
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
          vim.list_extend(opts.ensure_installed, { "zls" })
        end,
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        zls = {
          -- lsp: https://github.com/zigtools/zls
          -- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/zls.lua
          cmd = { "zls" },
          filetypes = { "zig", "zir" },
          root_markers = { "zls.json", "build.zig" },
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
