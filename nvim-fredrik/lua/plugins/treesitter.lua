return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    build = ":TSUpdate",
    opts = {
      auto_install = true,
      ensure_installed = { "diff", "regex", "markdown_inline", "http" },
      highlight = { enable = true },
      indent = { enable = true },
    },
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
