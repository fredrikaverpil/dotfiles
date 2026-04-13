require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/fei6409/log-highlight.nvim" },
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("log-highlight", { clear = true }),
    pattern = "log",
    once = true,
    callback = function()
      require("log-highlight").setup({})
    end,
  })
end)
