return {
  {
    "mason-org/mason.nvim",
    dependencies = {
      {
        "zapling/mason-lock.nvim",
        opts = {
          lockfile_path = require("fredrik.utils.environ").getenv("DOTFILES") .. "/nvim-fredrik/mason-lock.json",
        },
      },
      {
        "nvim-lualine/lualine.nvim",
        opts = {
          extensions = { "mason" },
        },
      },
    },

    ---@class MasonSettings
    opts = {
      -- for local development/testing; clone down the mason-registry locally
      -- registries = {
      --   "file:~/code/public/mason-registry",
      -- },

      -- Where Mason should put its bin location in your PATH. Can be one of:
      -- - "prepend" (default, Mason's bin location is put first in PATH)
      -- - "append" (Mason's bin location is put at the end of PATH)
      -- - "skip" (doesn't modify PATH)
      ---@type '"prepend"' | '"append"' | '"skip"'
      PATH = "append", -- picks tooling from local environment first
    },
    config = function(_, opts)
      local pip_extra_packages = opts.pip_extra_packages or {}
      opts.pip_extra_packages = nil -- don't pass custom key to mason.setup
      require("mason").setup(opts)

      local registry = require("mason-registry")

      -- handle opts.ensure_installed and pip_extra_packages after registry refresh
      registry.refresh(function()
        -- Install extra pip packages into Mason pypi venvs after (re)install.
        local InstallLocation = require("mason-core.installer.InstallLocation")
        for pkg_name, extra_pkgs in pairs(pip_extra_packages) do
          local ok, pkg = pcall(registry.get_package, pkg_name)
          if ok then
            local install_path = InstallLocation.global():package(pkg_name)
            local pip_bin = install_path .. "/venv/bin/pip"

            -- Install extra packages on future (re)installs.
            pkg:on("install:success", function()
              vim.schedule(function()
                local cmd = vim.list_extend({ pip_bin, "install" }, extra_pkgs)
                vim.notify(vim.inspect(cmd))
                vim.fn.jobstart(cmd, { detach = true })
              end)
            end)

            -- If already installed, ensure extra packages are present now.
            if pkg:is_installed() and vim.fn.executable(pip_bin) == 1 then
              vim.schedule(function()
                local cmd = vim.list_extend({ pip_bin, "install" }, extra_pkgs)
                vim.fn.jobstart(cmd, { detach = true })
              end)
            end
          end
        end

        if opts.ensure_installed == nil then
          return
        end

        for _, pkg_name in ipairs(opts.ensure_installed) do
          local pkg = registry.get_package(pkg_name)
          if not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },
}
