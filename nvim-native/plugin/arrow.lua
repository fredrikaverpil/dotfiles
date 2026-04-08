vim.pack.add({
  { src = "https://github.com/otavioschwanck/arrow.nvim" },
})

require("defer").on_ui_enter(function()
  require("arrow").setup({
    show_icons = true,
    leader_key = ";",
    buffer_leader_key = "m",
    always_show_path = true,
  })
end)
