return {

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
          vim.list_extend(opts.ensure_installed, { "tsserver", "vtsls" })
        end,
      },
      {
        "yioneko/nvim-vtsls",
        lazy = true,
        opts = {},
        config = function(_, opts)
          require("vtsls").config(opts)
        end,
      },
    },
    ft = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
    opts = {
      servers = {
        vtsls = {
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          },
        },
      },
    },
    keys = require("config.keymaps").setup_typescript_lsp_keymaps(),
    setup = {
      tsserver = function()
        -- disable tsserver
        return true
      end,
      vtsls = function(_, opts)
        -- copy typescript settings to javascript
        opts.settings.javascript = vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
        local plugins = vim.tbl_get(opts.settings, "vtsls", "tsserver", "globalPlugins")
        -- allow plugins to have a key for proper merging
        -- remove the key here
        if plugins then
          opts.settings.vtsls.tsserver.globalPlugins = vim.tbl_values(plugins)
        end
      end,
    },
  },
}
