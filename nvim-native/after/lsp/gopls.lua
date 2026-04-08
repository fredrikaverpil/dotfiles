-- Extend gopls for templ and gotmpl filetypes.
-- Runs after lsp/gopls.lua, merging into the base config.

---@type vim.lsp.Config
return {
  filetypes = { "go", "gomod", "gowork", "gosum", "templ", "gotmpl", "gohtml" },
  settings = {
    gopls = {
      templateExtensions = { "templ", "gotmpl", "gohtml", "tmpl" },
    },
  },
}
