vim.pack.add({
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/zapling/mason-lock.nvim" },
})

require("registry").add({
  lualine = { opts = { extensions = { "mason" } } },
})

require("defer").on_vim_enter(function()
  local merge = require("merge")
  local registry = require("registry")

  local opts = { PATH = "append" }
  require("mason").setup(merge(opts, registry.mason.opts or {}))

  require("mason-lock").setup({
    lockfile_path = vim.env.DOTFILES .. "/nvim-native/mason-lock.json",
  })

  require("mason-lspconfig").setup({
    automatic_enable = false, -- we handle vim.lsp.enable() ourselves
  })

  local mason_registry = require("mason-registry")
  mason_registry.refresh(function()
    local InstallLocation = require("mason-core.installer.InstallLocation")

    -- Install extra pip packages into Mason pypi venvs
    for pkg_name, extra_pkgs in pairs(registry.mason.pip_extra_packages or {}) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if ok then
        local install_path = InstallLocation.global():package(pkg_name)
        local pip_bin = install_path .. "/venv/bin/pip"

        -- Install extra packages on future (re)installs
        pkg:on("install:success", function()
          vim.schedule(function()
            vim.fn.jobstart(vim.list_extend({ pip_bin, "install" }, extra_pkgs), { detach = true })
          end)
        end)

        -- If already installed, ensure extra packages are present now
        if pkg:is_installed() and vim.fn.executable(pip_bin) == 1 then
          vim.schedule(function()
            vim.fn.jobstart(vim.list_extend({ pip_bin, "install" }, extra_pkgs), { detach = true })
          end)
        end
      end
    end

    -- Install missing mason tools
    for _, pkg_name in ipairs(registry.mason.ensure_installed or {}) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if ok and not pkg:is_installed() then
        pkg:install()
      end
    end
  end)
end)
