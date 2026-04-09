require("registry").add({
  lsp = { servers = { "rust_analyzer" } },
  mason = { ensure_installed = { "rust-analyzer", "codelldb" } },
})

-- TODO: evaluate rustaceanvim for LSP/DAP/neotest integration
