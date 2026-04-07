-- Mason: tool installer.
-- Ensures LSP servers, formatters, and linters are installed.

vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
})

require("mason").setup({
  PATH = "append", -- prefer local environment binaries
})

require("mason-lspconfig").setup({
  automatic_enable = false, -- we handle vim.lsp.enable() ourselves
})

local ensure_installed = {
  -- LSP
  "gopls",
  "lua-language-server",
  -- Formatters
  "gofumpt",
  "goimports",
  "gci",
  "golines",
  "stylua",
  "prettier",
  -- Linters
  "golangci-lint",
  "markdownlint",
  -- Test runners
  "gotestsum",
}

local registry = require("mason-registry")
registry.refresh(function()
  for _, pkg_name in ipairs(ensure_installed) do
    local ok, pkg = pcall(registry.get_package, pkg_name)
    if ok and not pkg:is_installed() then
      pkg:install()
    end
  end
end)
