return {

  {
    "stevearc/conform.nvim",
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "stylua" })
        end,
      },
    },
    ft = { "lua" },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
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
          vim.list_extend(opts.ensure_installed, { "lua_ls" })
        end,
      },
      {
        "folke/neoconf.nvim",
        dependencies = { "nvim-lspconfig" },
        cmd = "Neoconf",
        config = function()
          local plugin = require("lazy.core.config").spec.plugins["neoconf.nvim"]
          require("neoconf").setup(require("lazy.core.plugin").values(plugin, "opts", false))
        end,
      },
      { "folke/neodev.nvim", opts = {} }, -- recognize the 'vim' global
    },
    ft = { "lua" },
    opts = function(_, opts)
      opts.servers["lua_ls"] = {
        settings = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
              version = "LuaJIT",
            },
            workspace = {
              checkThirdParty = false,
            },
            codeLens = {
              enable = true,
            },
            completion = {
              callSnippet = "Replace",
            },
            doc = {
              privateName = { "^_" },
            },
            hint = {
              enable = true,
              setType = false,
              paramType = true,
              paramName = "Disable",
              semicolon = "Disable",
              arrayIndex = "Disable",
            },
          },
        },
      }
    end,
  },

  {
    "nvim-neotest/neotest",
    ft = { "lua" },
    dependencies = {
      {
        "nvim-neotest/neotest-plenary",
      },
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-plenary"] = {}
    end,
  },
}
