require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/hat0uma/csvview.nvim", version = vim.version.range("*") },
  })
end)
