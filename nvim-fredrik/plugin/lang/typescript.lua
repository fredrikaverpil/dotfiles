require("lang").register("typescript", {
  servers = { "vtsls" },
  mason = { "vtsls", "prettier" },
  formatters_by_ft = {
    javascript = { "prettier" },
    javascriptreact = { "prettier" },
    typescript = { "prettier" },
    typescriptreact = { "prettier" },
  },
})
