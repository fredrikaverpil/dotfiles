return {

  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local servers = {
        lua_ls = {
          -- cmd = {...},
          -- filetypes { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              workspace = {
                checkThirdParty = false,
                -- Tells lua_ls where to find all the Lua files that you have loaded
                -- for your neovim configuration.
                library = {
                  "${3rd}/luv/library",
                  unpack(vim.api.nvim_get_runtime_file("", true)),
                },
                -- If lua_ls is really slow on your computer, you can try this instead:
                -- library = { vim.env.VIMRUNTIME },
              },
              completion = {
                callSnippet = "Replace",
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- extend opts.servers with local servers variable
      opts.servers = vim.tbl_extend("force", servers, opts.servers or {})
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      local ensure_installed = vim.tbl_keys({})
      vim.list_extend(ensure_installed, {
        "stylua", -- Used to format lua code
      })
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      local formatters = require("conform.formatters")
      formatters.stylua.args =
        vim.list_extend({ "--indent-type", "Spaces", "--indent-width", "2" }, formatters.stylua.args)

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      local extend_formatters_with = {
        lua = { "stylua" },
      }
      for ft, formatters_ in pairs(extend_formatters_with) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        vim.list_extend(opts.formatters_by_ft[ft], formatters_)
      end
    end,
  },
}
