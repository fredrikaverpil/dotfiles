require("registry").add({
  lsp = { servers = { "ts_query_ls" } },
  mason = { ensure_installed = { "ts_query_ls" } },
})
