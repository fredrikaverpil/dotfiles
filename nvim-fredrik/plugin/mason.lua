require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/zapling/mason-lock.nvim" },
  })

  require("mason").setup({ PATH = "append" })

  require("mason-lock").setup({
    lockfile_path = vim.env.DOTFILES .. "/nvim-native/mason-lock.json",
  })

  require("mason-lspconfig").setup({
    automatic_enable = false, -- we handle vim.lsp.enable() ourselves
  })

  local ensure_installed = {
    "actionlint",
    "api-linter",
    "basedpyright",
    "bash-language-server",
    "biome",
    "buf",
    "codelldb",
    "debugpy",
    "delve",
    "dockerfile-language-server",
    "gci",
    "gofumpt",
    "goimports",
    "golangci-lint",
    "golines",
    "gopls",
    "gotestsum",
    "graphql-language-service-cli",
    "hadolint",
    "json-lsp",
    "lua-language-server",
    "markdownlint",
    "mypy",
    "nil-ls",
    "prettier",
    "protolint",
    "ruff",
    "rust-analyzer",
    "shfmt",
    "shellcheck",
    "stylua",
    "superhtml",
    "taplo",
    "templ",
    "terraform-ls",
    "tflint",
    "ts_query_ls",
    "vtsls",
    "yaml-language-server",
    "yamlfmt",
    "yamllint",
    "zls",
  }

  local mason_registry = require("mason-registry")
  mason_registry.refresh(function()
    for _, pkg_name in ipairs(ensure_installed) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if ok and not pkg:is_installed() then
        pkg:install()
      end
    end
  end)
end)
