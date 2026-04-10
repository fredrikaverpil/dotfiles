vim.pack.add({
  { src = "https://github.com/gbprod/yanky.nvim" },
})

require("startup").on_vim_enter(function()
  require("yanky").setup({})
end)

vim.keymap.set("n", "<leader>p", function()
  Snacks.picker.yanky()
end, { desc = "Yanky history" })
