vim.pack.add({
  { src = "https://github.com/gbprod/substitute.nvim" },
})

require("substitute").setup({
  on_substitute = function(event)
    require("yanky.integration").substitute()(event)
  end,
})

vim.keymap.set("n", "s", function()
  require("substitute").operator()
end, { desc = "Substitute" })
vim.keymap.set("n", "ss", function()
  require("substitute").line()
end, { desc = "Substitute line" })
vim.keymap.set("n", "S", function()
  require("substitute").eol()
end, { desc = "Substitute eol" })
vim.keymap.set("x", "x", function()
  require("substitute").visual()
end, { desc = "Substitute visual selection" })
