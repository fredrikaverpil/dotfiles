require("registry").add({
  lsp_servers = { "dockerls" },
  mason_tools = { "dockerfile-language-server", "hadolint" },
  lint = {
    linters_by_ft = { dockerfile = { "hadolint" } },
  },
})
