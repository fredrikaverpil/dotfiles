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
            "williamboman/mason.nvim",
            lazy = false,
          },
        },
      },
      {
        "hrsh7th/nvim-cmp",
        dependencies = {
          { "hrsh7th/cmp-buffer" },
          { "hrsh7th/cmp-path" },
          {
            "hrsh7th/cmp-nvim-lsp",
            dependencies = {
              {
                "L3MON4D3/LuaSnip",
                dependencies = {
                  "saadparwaiz1/cmp_luasnip",
                  "rafamadriz/friendly-snippets",
                },
              },
            },
          },
        },
        config = function()
          local cmp = require("cmp")
          require("luasnip.loaders.from_vscode").lazy_load()

          cmp.setup({
            snippet = {
              expand = function(args)
                require("luasnip").lsp_expand(args.body)
              end,
            },
            window = {
              completion = cmp.config.window.bordered(),
              documentation = cmp.config.window.bordered(),
            },
            mapping = cmp.mapping.preset.insert(require("config.keymaps").setup_cmp_keymaps(cmp)),
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "path" },
              { name = "luasnip" },
            }, {
              { name = "buffer" },
            }),
          })
        end,
      },
    },

    config = function(_, opts)
      local lspconfig = require("lspconfig")
      local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

      for server in pairs(opts.servers) do
        lspconfig[server].setup({
          capabilities = default_capabilities,
        })
      end

      require("config.keymaps").setup_lsp_keymaps()
    end,
  },
}
