require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/hat0uma/csvview.nvim" },
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("csv-opts", { clear = true }),
    pattern = "csv",
    once = true,
    callback = function()
      require("lazyload").call_once(function()
        require("csvview").setup()
      end)
    end,
  })
end)
