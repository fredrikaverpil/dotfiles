require("registry").add({
  lsp_servers = { "vtsls" },
  mason_ensure_installed = { "vtsls", "prettier" },
  code_runner = { filetype = { typescript = { "bun" } } },
  conform = {
    formatters_by_ft = {
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
    },
  },
})
