require("registry").add({
  lsp_servers = { "bashls" },
  mason_tools = { "bash-language-server", "shfmt", "shellcheck" },
  conform = {
    formatters_by_ft = { sh = { "shfmt" } },
  },
  lint = {
    linters_by_ft = { sh = { "shellcheck" } },
  },
})
