return {

  {
    "saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    version = "*",
    dependencies = {
      -- NOTE: https://github.com/Saghen/blink.compat is also available

      {
        "L3MON4D3/LuaSnip",
        dependencies = {
          "rafamadriz/friendly-snippets",
        },
        keys = require("config.keymaps").setup_luasnip_keymaps(),
        opts = function(_, opts)
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { os.getenv("DOTFILES") .. "/nvim-fredrik/snippets" },
          })
          return opts
        end,
      },
    },
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    --  build = "cargo build --release",
    config = function(_, opts)
      ---@module 'blink.cmp'
      ---@type blink.cmp.Config
      local base_opts = {
        accept = {
          expand_snippet = function(...)
            require("luasnip").lsp_expand(...)
          end,
        },
        trigger = {
          signature_help = {
            enabled = false, -- experimental, and already provided by noice
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
        sources = {
          completion = {
            enabled_providers = { "lsp", "path", "snippets", "buffer" },
          },
          providers = {},
        },
        keymap = require("config.keymaps").setup_blink_cmp_keymaps(),
      }
      local merged_opts = require("utils.table").deep_merge(base_opts, opts)
      require("blink.cmp").setup(merged_opts)
    end,
  },
}
