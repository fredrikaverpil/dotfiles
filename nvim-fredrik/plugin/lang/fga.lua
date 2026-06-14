require("lang").register("fga", {
  treesitter_custom_parsers = {
    fga = {
      filetype = "fga",
      install_info = {
        url = "https://github.com/matoous/tree-sitter-fga",
        branch = "main",
        generate = false,
        queries = "queries",
      },
    },
  },
})

vim.filetype.add({
  extension = {
    fga = "fga",
  },
})
