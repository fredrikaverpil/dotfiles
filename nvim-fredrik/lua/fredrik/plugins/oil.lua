return {
  {
    "stevearc/oil.nvim",
    dependencies = {
      {
        "nvim-mini/mini.icons",
        opts = {},
      },
    },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    opts = function(_, opts)
      opts = opts or {}

      opts.keymaps = opts.keymaps or {}
      opts.keymaps["<C-v>"] = { "actions.select", opts = { vertical = true } }
      opts.keymaps["<C-s>"] = { "actions.select", opts = { horizontal = true } }
      opts.keymaps["q"] = { "actions.close", mode = "n" }
      opts.view_options = { show_hidden = true }
      return opts
    end,
    keys = require("fredrik.config.keymaps").setup_oil_keymaps(),
  },

  {
    "malewicz1337/oil-git.nvim",
    dependencies = {
      "stevearc/oil.nvim",
      opts = {
        win_options = { signcolumn = "auto:2" },
      },
    },
    opts = {
      symbol_position = "signcolumn",
    },
  },

  {
    "JezerM/oil-lsp-diagnostics.nvim",
    dependencies = { "stevearc/oil.nvim" },
    opts = {},
  },
}
