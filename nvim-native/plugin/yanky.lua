-- yanky.nvim: improved yank/paste with history.

vim.pack.add({
  { src = "https://github.com/gbprod/yanky.nvim" },
})

require("yanky").setup({})

vim.keymap.set("n", "<leader>p", function()
  Snacks.picker.yanky()
end, { desc = "Yanky history" })
