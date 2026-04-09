require("registry").add({
  lsp = { servers = { "graphql" } },
  mason = { ensure_installed = { "graphql-language-service-cli" } },
})
