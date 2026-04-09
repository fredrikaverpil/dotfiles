require("registry").add({
  lsp = { servers = { "bashls" } },
  mason = { ensure_installed = { "bash-language-server", "shfmt", "shellcheck" } },
  conform = {
    opts = {
      formatters_by_ft = { sh = { "shfmt" } },
    },
  },
  lint = {
    linters_by_ft = { sh = { "shellcheck" } },
  },
})
