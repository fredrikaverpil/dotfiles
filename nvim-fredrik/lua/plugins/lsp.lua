return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        -- NOTE: this is here because mason-lspconfig must install servers prior to running nvim-lspconfig
        lazy = false,
        dependencies = {
          {
            -- NOTE: this is here because mason.setup must run prior to running nvim-lspconfig
            -- see mason.lua for more settings.
            "williamboman/mason.nvim",
            lazy = false,
          },
        },
      },
      {
        "hrsh7th/nvim-cmp",
        -- NOTE: this is here because we get the default client capabilities from cmp_nvim_lsp
        -- see cmp.lua for more settings.
      },
      {
        "artemave/workspace-diagnostics.nvim",
        enabled = false,
      },
      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        "j-hui/fidget.nvim",
        enabled = false, -- TODO: figure out how this status shows without fidget
        opts = {},
      },

      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      { "folke/neodev.nvim", opts = {} },
    },
    opts = {
      -- options for vim.diagnostic.config()
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = require("utils.defaults").icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = require("utils.defaults").icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = require("utils.defaults").icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = require("utils.defaults").icons.diagnostics.Info,
          },
        },
      },

      -- TODO: add example keys that can be passed into LSP somehow...
      -- Right now, capabilities is the only thing passed in. see:
      --

      -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
      -- Be aware that you also will need to properly configure your LSP server to
      -- provide the inlay hints.
      inlay_hints = {
        enabled = false,
      },
      -- Enable this to enable the builtin LSP code lenses on Neovim >= 0.10.0
      -- Be aware that you also will need to properly configure your LSP server to
      -- provide the code lenses.
      codelens = {
        enabled = false,
      },
      -- add any global capabilities here
      capabilities = {},
      -- options for vim.lsp.buf.format
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
    },
    config = function(_, opts)
      -- TODO: extend config with inspiration from
      -- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/init.lua

      -- diagnostics
      for name, icon in pairs(require("utils.defaults").icons.diagnostics) do
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end
      if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
        opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
          or function(diagnostic)
            local icons = require("utils.defaults").icons.diagnostics
            for d, icon in pairs(icons) do
              if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                return icon
              end
            end
          end
      end
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      -- TODO: explain capabilities, see
      -- https://github.com/nvim-lua/kickstart.nvim/blob/master/init.lua#L526
      local lspconfig = require("lspconfig")
      local client_capabilities = vim.lsp.protocol.make_client_capabilities()
      local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

      local capabilities = vim.tbl_deep_extend("force", {}, client_capabilities, default_capabilities or {}, opts.capabilities or {})

      for server in pairs(opts.servers) do
        lspconfig[server].setup({
          capabilities = vim.deepcopy(capabilities),
          on_attach = function(client, bufnr)
            require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
          end,
        })
      end

      require("config.keymaps").setup_lsp_keymaps()
    end,
  },
}
