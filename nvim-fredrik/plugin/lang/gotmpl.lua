vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("native-gotmpl-opts", { clear = true }),
  pattern = "gotmpl",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})

vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
  },
  pattern = {
    [".*%.go%.tmpl"] = "gotmpl",
  },
})
