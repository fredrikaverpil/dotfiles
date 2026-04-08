-- Nix: formatters.
-- NOTE: nixfmt not available via Mason on macOS, installed via Nix instead.

require("conform").setup({
  formatters_by_ft = {
    nix = { "nixfmt" },
  },
})
