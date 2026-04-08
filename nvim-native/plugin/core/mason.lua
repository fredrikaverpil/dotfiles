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
  -- LSP (mason-lspconfig handles name mapping for these)
  "gopls",
  "lua-language-server",
  "basedpyright",
  "ruff",
  "dockerfile-language-server",
  "json-lsp",
  "bash-language-server",
  "zls",
  "ts_query_ls",
  "templ",
  "graphql-language-service-cli",
  "superhtml",
  "taplo",
  "vtsls",
  "yaml-language-server",
  "terraform-ls",
  "rust-analyzer",
  "nil-ls",
  -- Formatters
  "gofumpt",
  "goimports",
  "gci",
  "golines",
  "stylua",
  "prettier",
  "biome",
  "shfmt",
  "yamlfmt",
  "buf",
  -- Linters
  "golangci-lint",
  "markdownlint",
  "hadolint",
  "shellcheck",
  "mypy",
  "yamllint",
  "actionlint",
  "tflint",
  "protolint",
  "api-linter",
  -- DAP
  "debugpy",
  "delve",
  "codelldb",
  -- Other tools
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
