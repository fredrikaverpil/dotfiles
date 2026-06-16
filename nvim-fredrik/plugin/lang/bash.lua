require("lang").register("bash", {
  -- shellcheck is not wired into nvim-lint: bashls runs it itself when the
  -- binary is on PATH, which would yield duplicate diagnostics.
  mason = { "bash-language-server", "shellcheck", "shfmt" },
})
