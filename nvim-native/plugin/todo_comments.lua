-- Todo comment highlighting and search (via snacks picker).

vim.pack.add({
  { src = "https://github.com/folke/todo-comments.nvim" },
})

require("todo-comments").setup({})
