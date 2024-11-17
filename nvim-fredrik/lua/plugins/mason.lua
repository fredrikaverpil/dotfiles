return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
    config = function(_, opts)
      require("mason").setup(opts)

      -- handle opts.ensure_installed
      local registry = require("mason-registry")
      registry.refresh(function()
        for _, pkg_name in ipairs(opts.ensure_installed) do
          -- print("loading " .. pkg_name)
          local pkg = registry.get_package(pkg_name)
          if not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
  },

  {
    "zapling/mason-lock.nvim",
    init = function()
      require("mason-lock").setup({
        lockfile_path = os.getenv("DOTFILES") .. "/nvim-fredrik/mason-lock.json",
      })
    end,
  },
}
