require("registry").add({
  lsp_servers = { "rust_analyzer" },
  mason_ensure_installed = { "rust-analyzer", "codelldb" },
})

-- TODO: evaluate rustaceanvim for LSP/DAP/neotest integration
