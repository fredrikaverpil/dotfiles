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
          print("base: configuring nvim-cmp")
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
            mapping = cmp.mapping.preset.insert({
              ["<C-u>"] = cmp.mapping.scroll_docs(-4),
              ["<C-d>"] = cmp.mapping.scroll_docs(4),
              ["<C-Space>"] = cmp.mapping.complete(),
              ["<C-e>"] = cmp.mapping.abort(),
              ["<CR>"] = cmp.mapping.confirm({ select = true }),
            }),
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "luasnip" },
            }, {
              { name = "buffer" },
            }),
          })
        end,
      },
    },

    config = function(_, opts)
      print("base: nvim-lspconfig setup")

      -- uncomment for debugging
      print(vim.inspect(opts))

      local lspconfig = require("lspconfig")
      local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- call set up for each server in opts.servers
      for server in pairs(opts.servers) do
        lspconfig[server].setup({
          capabilities = default_capabilities,
        })
      end

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {}) -- TODO: shows a list?!
      vim.keymap.set("n", "gr", builtin.lsp_references, {})
      -- TODO: add more keymaps
    end,
  },
}
