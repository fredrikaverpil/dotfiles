require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/mason-org/mason.nvim", version = vim.version.range("*") },
    { src = "https://github.com/zapling/mason-lock.nvim" },
  })

  require("mason").setup({ PATH = "append" })

  require("mason-lock").setup({
    lockfile_path = vim.env.DOTFILES .. "/nvim-fredrik/mason-lock.json",
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
    "elixir-ls",
    "gci",
    "gofumpt",
    "goimports",
    "golangci-lint",
    "golines",
    "gopls",
    "gotestsum",
    "graphql-language-service-cli",
    "hadolint",
    "impl", -- used by go-impl.nvim
    "json-lsp",
    "lua-language-server",
    "markdownlint",
    "mypy",
    "nil",
    "prettier",
    "protolint",
    "ruff",
    "rust-analyzer",
    "shellcheck", -- bashls runs shellcheck itself; not wired into nvim-lint to avoid dupes
    "shfmt",
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

  -- Project-local additions from a .nvim.lua (exrc), e.g.:
  --   Config.mason_extra = {
  --     mason = { "mdformat" },
  --     mason_pip = { mdformat = { "mdformat-gfm==1.0.0" } },
  --   }
  -- exrc runs at startup step 7c, before this VimEnter callback, so the table is
  -- always populated by the time it is read here.
  local extra = Config.mason_extra or {}
  ensure_installed = vim.list_extend(ensure_installed, extra.mason or {})
  local mason_pip = extra.mason_pip or {}

  -- mason_pip packages are installed into the mason package's venv. Mason
  -- recreates the venv on install/update (wiping them), so they are re-applied
  -- via the install:success event; the pass after refresh() covers packages
  -- that are already installed.
  local function install_mason_pip(pkg_name)
    local extras = mason_pip[pkg_name]
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
    for _, pkg_name in ipairs(ensure_installed) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if not ok then
        vim.notify(("mason: unknown package %q"):format(pkg_name), vim.log.levels.WARN)
      elseif not pkg:is_installed() then
        pkg:install()
      end
    end

    for pkg_name in pairs(mason_pip) do
      local ok, pkg = pcall(mason_registry.get_package, pkg_name)
      if ok and pkg:is_installed() then
        install_mason_pip(pkg_name)
      end
    end
  end)
end)
