return {

  -- add more treesitter parsers, used for e.g. theming and other plugins
  {
    "nvim-treesitter/nvim-treesitter",
    -- opts will be merged with the parent spec
    opts = {
      ensure_installed = {
        "bash",
        "go",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rust",
        "sql",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- https://github.com/nvim-treesitter/nvim-treesitter-context
  {
    "nvim-treesitter/nvim-treesitter-context",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
}
