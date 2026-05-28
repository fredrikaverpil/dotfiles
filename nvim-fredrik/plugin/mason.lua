require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/mason-org/mason.nvim", version = vim.version.range("*") },
    { src = "https://github.com/mason-org/mason-lspconfig.nvim", version = vim.version.range("*") },
    { src = "https://github.com/zapling/mason-lock.nvim" },
  })

  require("mason").setup({ PATH = "append" })

  require("mason-lock").setup({
    lockfile_path = vim.env.DOTFILES .. "/nvim-fredrik/mason-lock.json",
  })

  require("mason-lspconfig").setup({
    automatic_enable = false, -- we handle vim.lsp.enable() ourselves
  })

  -- Tool list aggregated from plugin/lang/*.lua via require("lang").register().
  local ensure_installed = require("lang").mason_tools()

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
