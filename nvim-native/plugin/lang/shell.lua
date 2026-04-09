require("registry").add({
  lsp_servers = { "bashls" },
  mason_ensure_installed = { "bash-language-server", "shfmt", "shellcheck" },
  conform = {
    formatters_by_ft = { sh = { "shfmt" } },
  },
  lint = {
    linters_by_ft = { sh = { "shellcheck" } },
  },
})
