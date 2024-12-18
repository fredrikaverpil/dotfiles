return {

  -- NOTE: this plugin is only used for cmdline completions. All other completions use blink.nvim.

  {
    "hrsh7th/nvim-cmp",
    lazy = true,
    event = "CmdlineEnter",
    enabled = true,
    dependencies = {
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-buffer" },
      -- {
      --   "hrsh7th/cmp-nvim-lsp",
      --   dependencies = {
      --     {
      --       "L3MON4D3/LuaSnip",
      --       dependencies = {
      --         "saadparwaiz1/cmp_luasnip",
      --         "rafamadriz/friendly-snippets",
      --       },
      --       keys = require("fredrik.config.keymaps").setup_snippets_keymaps(),
      --     },
      --   },
      -- },
      { "hrsh7th/cmp-cmdline" },
    },

    config = function(_, opts)
      local cmp = require("cmp")
      -- require("luasnip.loaders.from_vscode").lazy_load()

      -- local sources = opts.sources or {}
      -- vim.list_extend(sources, {
      --   { name = "nvim_lsp" },
      --   { name = "path" },
      --   { name = "luasnip" },
      --   { name = "buffer" },
      -- })

      -- cmp.setup({
      --   snippet = {
      --     expand = function(args)
      --       require("luasnip").lsp_expand(args.body)
      --     end,
      --   },
      --   window = {
      --     completion = cmp.config.window.bordered(),
      --     documentation = cmp.config.window.bordered(),
      --   },
      --   mapping = cmp.mapping.preset.insert(require("fredrik.config.keymaps").setup_cmp_keymaps(cmp)),
      --   sources = cmp.config.sources(sources),
      -- })

      -- `/` cmdline setup.
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      -- `:` cmdline setup.
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          {
            name = "cmdline",
            option = {
              ignore_cmds = { "Man", "!" },
            },
          },
        }),
      })
    end,
  },
}
