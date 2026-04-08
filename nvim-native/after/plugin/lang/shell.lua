-- Shell: formatters and linters.

require("conform").setup({
  formatters_by_ft = {
    sh = { "shfmt" },
  },
})

require("lint").linters_by_ft.sh = { "shellcheck" }
