return {

  {
    "stevearc/conform.nvim",
    lazy = true,
    ft = { "lua" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { "stylua" })
        end,
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    lazy = true,
    -- ft = { "lua" },
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
        "folke/lazydev.nvim",
        opts = {
          library = {

            -- Library paths can be absolute
            -- "~/projects/my-awesome-lib",

            -- Or relative, which means they will be resolved from the plugin dir.
            "lazy.nvim",
            "neotest",
            "plenary",

            -- It can also be a table with trigger words / mods
            -- Only load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },

            -- always load the LazyVim library
            -- "LazyVim",

            -- Only load the lazyvim library when the `LazyVim` global is found
            { path = "LazyVim", words = { "LazyVim" } },
            { path = "snacks.nvim", words = { "Snacks" } },
            { path = "lazy.nvim", words = { "LazyVim" } },
          },
        },
      },
      { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
      { -- optional blink completion source for require statements and module annotations
        "saghen/blink.cmp",
        opts = {
          sources = {
            -- add lazydev to your completion providers
            default = { "lazydev" },
            providers = {
              lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                -- make lazydev completions top priority (see `:h blink.cmp`)
                score_offset = 100,
              },
            },
          },
        },
      },
    },
    opts = {
      servers = {
        ---@type vim.lsp.Config
        lua_ls = {
          -- lsp: https://github.com/luals/lua-language-server
          -- reference: https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/lua_ls.lua
          cmd = { "lua-language-server" },
          filetypes = { "lua" },
          root_markers = { "lua", ".git" },
          single_file_support = true,
          log_level = vim.lsp.protocol.MessageType.Warning,
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
              },
              workspace = {
                checkThirdParty = false,
              },
              codeLens = {
                enable = false, -- causes annoying flickering
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
        },
      },
    },
  },

  {
    "nvim-neotest/neotest",
    lazy = true,
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
