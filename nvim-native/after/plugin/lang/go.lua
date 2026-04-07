-- Go: formatters, linters, and LSP inlay-hints toggle.
-- Runs after plugin/ is fully sourced (after/plugin/ loading order).

require("conform").setup({
  formatters_by_ft = {
    go = { "goimports", "gci", "gofumpt", "golines" },
  },
  formatters = {
    goimports = {
      args = { "-srcdir", "$FILENAME" },
    },
    gci = {
      args = { "write", "--skip-generated", "-s", "standard", "-s", "default", "--skip-vendor", "$FILENAME" },
    },
    gofumpt = {
      prepend_args = { "-extra", "-w", "$FILENAME" },
      stdin = false,
    },
    golines = {
      prepend_args = { "--base-formatter=gofumpt", "--ignore-generated", "--tab-len=1", "--max-len=120" },
    },
  },
})

require("lint").linters_by_ft.go = { "golangcilint" }
