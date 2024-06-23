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
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {

            -- Library paths can be absolute
            -- "~/projects/my-awesome-lib",

            -- Or relative, which means they will be resolved from the plugin dir.
            "lazy.nvim",
            "luvit-meta/library",
            "neotest",
            "plenary",

            -- It can also be a table with trigger words / mods
            -- Only load luvit types when the `vim.uv` word is found
            { path = "luvit-meta/library", words = { "vim%.uv" } },

            -- always load the LazyVim library
            -- "LazyVim",

            -- Only load the lazyvim library when the `LazyVim` global is found
            { path = "LazyVim", words = { "LazyVim" } },

            -- Load the wezterm types when the `wezterm` module is required
            -- Needs `justinsgithub/wezterm-types` to be installed
            { path = "wezterm-types", mods = { "wezterm" } },
          },
        },
      },
      { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
      { -- optional completion source for require statements and module annotations
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
          opts.sources = opts.sources or {}
          table.insert(opts.sources, {
            name = "lazydev",
            group_index = 0, -- set group index to 0 to skip loading LuaLS completions
          })
        end,
      },
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
