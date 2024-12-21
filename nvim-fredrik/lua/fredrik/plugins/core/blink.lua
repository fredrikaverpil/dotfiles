return {

  {
    "saghen/blink.cmp",
    lazy = false, -- lazy loading handled internally
    version = "*",
    dependencies = {
      -- NOTE: https://github.com/Saghen/blink.compat is also available
      "rafamadriz/friendly-snippets",
    },

    -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    --  build = "cargo build --release",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {

      keymap = require("fredrik.config.keymaps").setup_blink_cmp_keymaps(),

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

      -- default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, via `opts_extend`
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          snippets = {
            opts = {
              friendly_snippets = true,
              search_paths = { os.getenv("DOTFILES") .. "/nvim-fredrik/snippets" },
            },
          },
        },
      },
    },

    -- allows extending the enabled_providers array elsewhere in your config
    -- without having to redefine it
    opts_extend = {
      "sources.completion.enabled_providers",
      "sources.default",
    },
  },
}
