vim.pack.add({
  { src = "https://github.com/hat0uma/csvview.nvim" },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "csv",
  once = true,
  callback = function()
    require("csvview").setup()
  end,
})
