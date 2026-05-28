require("lang").register("bash", {
  servers = { "bashls" },
  mason = { "bash-language-server", "shellcheck", "shfmt" },
  formatters_by_ft = { sh = { "shfmt" } },
  linters_by_ft = { sh = { "shellcheck" } },
})
