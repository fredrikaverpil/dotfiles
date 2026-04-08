---@type vim.lsp.Config
return {
  cmd = { "ts_query_ls" },
  filetypes = { "query" },
  root_markers = { ".tsqueryrc.json", ".git" },
  init_options = {
    parser_aliases = {
      ecma = "javascript",
      jsx = "javascript",
      php_only = "php",
    },
    parser_install_directories = {
      vim.fn.stdpath("data") .. "/site/parser",
    },
  },
}
