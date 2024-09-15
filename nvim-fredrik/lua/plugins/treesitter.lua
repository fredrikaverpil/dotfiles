return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    build = ":TSUpdate",
    opts = function(_, opts)
      local defaults = {
        auto_install = true,
        ensure_installed = { "diff", "regex", "markdown_inline", "http" },
        highlight = { enable = true },
        indent = { enable = true },
      }
      local merged = require("utils.table").deep_tbl_extend(defaults, opts)
      return merged
    end,
    config = function(_, opts)
      local config = require("nvim-treesitter.configs")
      config.setup(opts)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter", lazy = true },
  },
}
