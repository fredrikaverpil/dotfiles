require("lazyload").on_vim_enter(function()
  if Config.use_nvim_treesitter then
    vim.pack.add({
      { src = "https://github.com/folke/ts-comments.nvim" },
    })

    require("ts-comments").setup()
  end
end)
