require("registry").add({
  lsp = { servers = { "dockerls" } },
  mason = { ensure_installed = { "dockerfile-language-server", "hadolint" } },
  lint = {
    linters_by_ft = { dockerfile = { "hadolint" } },
  },
})
