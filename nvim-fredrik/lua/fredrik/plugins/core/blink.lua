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
      cmdline = {
        enabled = true,
        completion = {
          menu = { auto_show = true },
          ghost_text = { enabled = true },
        },
      },
      completion = {
        list = {
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
        documentation = {
          auto_show = true,
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
        },
      },
      signature = {
        enabled = true, -- experimental, can also be provided by noice
      },
      appearance = {
        kind_icons = require("fredrik.utils.icons").icons.kinds,
      },
      -- default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, via `opts_extend`
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        providers = {
          snippets = {
            opts = {
              friendly_snippets = true,
              search_paths = { require("fredrik.utils.environ").getenv("DOTFILES") .. "/nvim-fredrik/snippets" },
            },
          },
        },
      },
    },
    opts_extend = {
      "sources.default",
    },
    config = function(_, opts)
      require("blink.cmp").setup(opts)
    end,
  },
}
