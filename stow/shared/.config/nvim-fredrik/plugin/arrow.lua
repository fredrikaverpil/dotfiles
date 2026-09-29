require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/otavioschwanck/arrow.nvim" },
  })

  require("arrow").setup({
    show_icons = true,
    leader_key = ";",
    buffer_leader_key = "m",
    always_show_path = true,
  })
end)
