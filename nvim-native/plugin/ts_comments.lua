-- ts-comments: better JS/TS comment handling.

vim.pack.add({
  { src = "https://github.com/folke/ts-comments.nvim" },
})

require("ts-comments").setup()
