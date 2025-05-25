return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    branch = "master", -- NOTE: master is frozen, continued work will be done in the main branch
    event = "BufRead",
    build = ":TSUpdate",
    opts = function(_, opts)
      local defaults = {
        auto_install = true,
        ensure_installed = { "diff", "regex", "markdown_inline", "http" },
        highlight = { enable = true },
        indent = { enable = true },
      }
      local merged = require("fredrik.utils.table").deep_merge(defaults, opts)
      return merged
    end,
    config = function(buf, opts)
      local config = require("nvim-treesitter.configs")
      config.setup(opts)
      require("fredrik.config.options").treesitter_foldexpr()
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufRead",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      event = "BufRead",
    },
    opts = {
      multiwindow = true,
    },
  },
}
