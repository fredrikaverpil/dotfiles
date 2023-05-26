return {

  -- add more treesitter parsers, used for e.g. theming and other plugins
  {
    "nvim-treesitter/nvim-treesitter",
    -- opts will be merged with the parent spec
    opts = {
      ensure_installed = {
        "bash",
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
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },
}
