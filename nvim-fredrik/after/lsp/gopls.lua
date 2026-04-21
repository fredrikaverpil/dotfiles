---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gosum", "templ", "gotmpl", "gohtml" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
        ST1000 = true, -- Incorrect or missing package comment
        ST1020 = true, -- Exported function doc should start with function name
        ST1021 = true, -- Exported type doc should start with type name
      },
      hints = {
        parameterNames = true,
        assignVariableTypes = true,
        constantValues = true,
        compositeLiteralTypes = true,
        compositeLiteralFields = true,
        functionTypeParameters = true,
      },
      directoryFilters = { "-**/node_modules", "-**/.git" },
      gofumpt = false, -- handled by conform
      semanticTokens = false, -- let treesitter handle highlighting
      staticcheck = true,
      templateExtensions = { "templ", "gotmpl", "gohtml", "tmpl" },
      vulncheck = "imports",
      -- go-impl.nvim uses workspace/symbol to populate its interface picker.
      -- "workspace" (default) excludes stdlib/deps, so e.g. typing "reader"
      -- would not surface io.Reader. "all" fixes that.
      symbolScope = "all",
      -- FastFuzzy makes the same workspace/symbol queries fuzzy rather than
      -- prefix-only, improving match quality in the go-impl picker.
      symbolMatcher = "FastFuzzy",
    },
  },
}
