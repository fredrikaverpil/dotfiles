require("registry").add({
  lsp = { servers = { "templ" } },
  mason = { ensure_installed = { "templ" } },
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
