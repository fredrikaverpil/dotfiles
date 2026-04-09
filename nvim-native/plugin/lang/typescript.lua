require("registry").add({
  lsp = { servers = { "vtsls" } },
  mason = { ensure_installed = { "vtsls", "prettier" } },
  code_runner = { opts = { filetype = { typescript = { "bun" } } } },
  conform = {
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
    },
  },
})
