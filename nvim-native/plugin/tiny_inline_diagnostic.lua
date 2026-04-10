vim.pack.add({
  { src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim" },
})

require("startup").on_vim_enter(function()
  require("tiny-inline-diagnostic").setup({
    options = {
      show_all_diags_on_cursorline = true,
      multilines = {
        enabled = true,
        always_show = true,
      },
      show_source = {
        enabled = true,
      },
    },
  })
end)
