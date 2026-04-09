vim.pack.add({
  { src = "https://github.com/gbprod/yanky.nvim" },
})

require("defer").on_ui_enter(function()
  require("yanky").setup({})

  vim.keymap.set("n", "<leader>p", function()
    Snacks.picker.yanky()
  end, { desc = "Yanky history" })
end)
