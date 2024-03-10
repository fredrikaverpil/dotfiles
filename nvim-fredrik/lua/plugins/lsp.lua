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
      local lspconfig = require("lspconfig")
      local default_capabilities = require("cmp_nvim_lsp").default_capabilities()

      for server in pairs(opts.servers) do
        lspconfig[server].setup({
          capabilities = default_capabilities,
        })
      end

      local map = function(keys, func, desc)
        vim.keymap.set("n", keys, func, { desc = "LSP: " .. desc })
      end

      -- Jump to the definition of the word under your cursor.
      --  This is where a variable was first declared, or where a function is defined, etc.
      --  To jump back, press <C-T>.
      map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

      -- Find references for the word under your cursor.
      map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

      -- Jump to the implementation of the word under your cursor.
      --  Useful when your language has ways of declaring types without an actual implementation.
      map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

      -- Jump to the type of the word under your cursor.
      --  Useful when you're not sure what type a variable is and you want to see
      --  the definition of its *type*, not where it was *defined*.
      map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

      -- Fuzzy find all the symbols in your current document.
      --  Symbols are things like variables, functions, types, etc.
      map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

      -- Fuzzy find all the symbols in your current workspace
      --  Similar to document symbols, except searches over your whole project.
      map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

      -- Rename the variable under your cursor
      --  Most Language Servers support renaming across files, etc.
      map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

      -- Execute a code action, usually your cursor needs to be on top of an error
      -- or a suggestion from your LSP for this to activate.
      map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

      -- Opens a popup that displays documentation about the word under your cursor
      --  See `:help K` for why this keymap
      map("K", vim.lsp.buf.hover, "Hover Documentation")

      map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    end,
  },
}
