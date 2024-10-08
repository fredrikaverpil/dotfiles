return {

  {
    "saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    dependencies = {
      -- NOTE: https://github.com/Saghen/blink.compat is also available

      {
        "rafamadriz/friendly-snippets",
      },

      -- FIXME: do I need luasnup?
      -- {
      --   "L3MON4D3/LuaSnip",
      --   dependencies = {
      --     "rafamadriz/friendly-snippets",
      --   },
      --   keys = require("config.keymaps").setup_snippets_keymaps(),
      --   opts = function(_, opts)
      --     vim.notify("YEP")
      --     require("luasnip.loaders.from_vscode").lazy_load()
      --     return opts
      --   end,
      -- },
    },

    version = "*",
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    --  build = "cargo build --release",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {

      accept = {
        -- FIXME: do I need luasnip?
        -- expand_snippet = function(...)
        --   require("luasnip").lsp_expand(...)
        -- end,

        expand_snippet = vim.snippet.expand,
      },
      trigger = {
        signature_help = {
          enabled = true,
        },
      },
      windows = {
        autocomplete = {
          selection = "manual",
        },
        documentation = {
          auto_show = true,
        },
      },

      keymap = require("config.keymaps").setup_blink_cmp_keymaps(),
    },
  },
}
