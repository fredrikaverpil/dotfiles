require("registry").add({
  lsp_servers = { "vtsls" },
  mason_tools = { "vtsls", "prettier" },
  code_runner = { typescript = { "bun" } },
  conform = {
    formatters_by_ft = {
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
    },
  },
})
