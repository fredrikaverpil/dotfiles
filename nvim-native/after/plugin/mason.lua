vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/zapling/mason-lock.nvim" },
})

-- Add mason bin to PATH eagerly so LSP/formatters/linters find installed tools
vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.stdpath("data") .. "/mason/bin"

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  require("mason").setup({
    PATH = "skip", -- we already added it above
  })

  require("mason-lock").setup({
    lockfile_path = vim.env.DOTFILES .. "/nvim-native/mason-lock.json",
  })

  require("mason-lspconfig").setup({
    automatic_enable = false, -- we handle vim.lsp.enable() ourselves
  })

  local registry = require("registry")
  local mason_registry = require("mason-registry")
  mason_registry.refresh(function()
    for _, pkg_name in ipairs(registry.mason_tools) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if ok and not pkg:is_installed() then
        pkg:install()
      end
    end
  end)
end

-- Proxy commands that trigger lazy initialization
for _, cmd in ipairs({ "Mason", "MasonInstall", "MasonUpdate", "MasonLog", "MasonUninstall", "MasonUninstallAll" }) do
  vim.api.nvim_create_user_command(cmd, function(opts)
    init() -- registers real commands via mason.setup()
    vim.cmd(cmd .. " " .. opts.args)
  end, { nargs = "*", desc = cmd })
end
