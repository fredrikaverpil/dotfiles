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
        opts = function(_, opts)
          require("luasnip.loaders.from_vscode").lazy_load({
            paths = { os.getenv("DOTFILES") .. "/nvim-fredrik/snippets" },
          })
          return opts
        end,
        keys = require("fredrik.config.keymaps").setup_luasnip_keymaps(),
      },
    },
    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    --  build = "cargo build --release",
    config = function(_, opts)
      ---@module 'blink.cmp'
      ---@type blink.cmp.Config
      local base_opts = {
        completion = {
          list = {
            selection = "manual",
          },
          documentation = {
            auto_show = true,
          },
        },
        signature = {
          enabled = false, -- experimental, and already provided by noice
        },
        sources = {
          completion = {
            enabled_providers = { "lsp", "path", "snippets", "buffer" },
          },
          -- providers = {}, -- this seems to include a bunch of things I don't want to re-specify here...
        },
        keymap = require("fredrik.config.keymaps").setup_blink_cmp_keymaps(),
      }
      local merged_opts = require("fredrik.utils.table").deep_merge(base_opts, opts)
      require("blink.cmp").setup(merged_opts)
    end,
  },
}
