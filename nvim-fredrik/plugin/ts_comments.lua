require("lazyload").on_vim_enter(function()
  if Config.use_treesitter_parser then
    vim.pack.add({
      { src = "https://github.com/folke/ts-comments.nvim" },
    })

    require("ts-comments").setup()
  end
end)
