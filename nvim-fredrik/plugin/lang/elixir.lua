require("lang").register("elixir", {
  servers = { "elixirls" },
  mason = { "elixir-ls" },
  formatters_by_ft = {
    elixir = { "mix" },
    heex = { "mix" },
  },
  code_runner = { elixir = { "elixir" } },
})
