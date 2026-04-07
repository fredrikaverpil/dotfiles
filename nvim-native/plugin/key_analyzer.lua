-- key-analyzer: analyze keymap usage and conflicts.

vim.pack.add({
  { src = "https://github.com/meznaric/key-analyzer.nvim" },
})

require("key-analyzer").setup({})
