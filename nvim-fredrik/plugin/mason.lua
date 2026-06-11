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

  -- mason (package list) and mason_pip aggregated from plugin/lang/*.lua via
  -- require("lang").register().
  local lang = require("lang").spec()

  -- mason_pip packages are installed into the mason package's venv. Mason
  -- recreates the venv on install/update (wiping them), so they are re-applied
  -- via the install:success event; the pass after refresh() covers packages
  -- that are already installed.
  local function install_mason_pip(pkg_name)
    local extras = lang.mason_pip[pkg_name]
    if not extras then
      return
    end
    local root = require("mason.settings").current.install_root_dir
    local pip = vim.fs.joinpath(root, "packages", pkg_name, "venv", "bin", "pip")
    vim.system(vim.list_extend({ pip, "install", "--quiet" }, extras), {}, function(out)
      if out.code ~= 0 then
        vim.schedule(function()
          vim.notify(("pip extras for %s failed:\n%s"):format(pkg_name, out.stderr or ""), vim.log.levels.ERROR)
        end)
      end
    end)
  end

  local mason_registry = require("mason-registry")

  mason_registry:on(
    "package:install:success",
    vim.schedule_wrap(function(pkg)
      install_mason_pip(pkg.name)
    end)
  )

  mason_registry:on(
    "package:install:failed",
    vim.schedule_wrap(function(pkg, err)
      vim.notify(("mason install of %s failed: %s"):format(pkg.name, vim.inspect(err)), vim.log.levels.ERROR)
    end)
  )

  mason_registry.refresh(function()
    for _, pkg_name in ipairs(lang.mason) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if ok and not pkg:is_installed() then
        pkg:install()
      end
    end

    for pkg_name in pairs(lang.mason_pip) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if ok and pkg:is_installed() then
        install_mason_pip(pkg_name)
      end
    end
  end)
end)
