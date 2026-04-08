require("registry").add({
  lsp_servers = { "templ" },
  mason_tools = { "templ" },
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
