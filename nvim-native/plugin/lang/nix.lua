local registry = require("registry")

-- nixfmt on macOS is installed via Nix, not Mason
registry.add({
  mason_ensure_installed = { "nil-ls" },
  conform = {
    formatters_by_ft = { nix = { "nixfmt" } },
  },
})

-- Only enable nil_ls if nix is available
if vim.fn.executable("nix") == 1 then
  registry.add({ lsp_servers = { "nil_ls" } })
end
