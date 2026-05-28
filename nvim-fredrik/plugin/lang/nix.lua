require("lang").register("nix", {
  servers = { "nil_ls" },
  mason = { "nil-ls" },
  -- nixfmt is provided by Nix, not Mason.
  formatters_by_ft = { nix = { "nixfmt" } },
})
