local registry = require("registry")

vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/zapling/mason-lock.nvim" },
})

require("mason").setup({
  PATH = "append", -- prefer local environment binaries
})

require("mason-lock").setup({
  lockfile_path = vim.env.DOTFILES .. "/nvim-native/mason-lock.json",
})

require("mason-lspconfig").setup({
  automatic_enable = false, -- we handle vim.lsp.enable() ourselves
})

local mason_registry = require("mason-registry")
mason_registry.refresh(function()
  for _, pkg_name in ipairs(registry.mason_tools) do
    local ok, pkg = pcall(mason_registry.get_package, pkg_name)
    if ok and not pkg:is_installed() then
      pkg:install()
    end
  end
end)
