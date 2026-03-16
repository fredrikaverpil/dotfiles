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
      opts.keymaps = {} or opts.keymaps

      -- remove, avoid confusion
      opts.keymaps["<C-h>"] = nil

      opts.keymaps["<C-v>"] = { "actions.select", opts = { vertical = true } }
      opts.keymaps["<C-s>"] = { "actions.select", opts = { horizontal = true } }
      opts.keymaps["<C-r>"] = "actions.refresh"
      opts.keymaps["q"] = { "actions.close", mode = "n" }
      opts.keymaps["h"] = { "actions.toggle_hidden", mode = "n" }
      opts.keymaps["s"] = { "actions.change_sort", mode = "n" }

      opts.win_options = { signcolumn = "auto:2" }
      opts.view_options = { show_hidden = true }
      return opts
    end,
    keys = require("fredrik.config.keymaps").setup_oil_keymaps(),
  },

  {
    "malewicz1337/oil-git.nvim",
    dependencies = { "stevearc/oil.nvim" },
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
