vim.filetype.add({
  extension = {
    gotmpl = "gotmpl",
    gohtml = "gotmpl",
  },
  pattern = {
    [".*%.go%.tmpl"] = "gotmpl",
  },
})
