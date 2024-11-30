return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    event = "BufRead",
    build = ":TSUpdate",
    opts = function(_, opts)
      local defaults = {
        auto_install = true,
        ensure_installed = { "diff", "regex", "markdown_inline", "http" },
        highlight = { enable = true },
        indent = { enable = true },
      }
      local merged = require("utils.table").deep_merge(defaults, opts)
      return merged
    end,
    config = function(_, opts)
      local config = require("nvim-treesitter.configs")
      config.setup(opts)
      if vim.opt.foldexpr == nil then
        vim.notify("Using treesitter for folds")
        vim.opt.foldmethod = "expr"
        vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
      end
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
