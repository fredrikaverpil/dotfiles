return {
  {
    "williamboman/mason.nvim",
    lazy = true,
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
      require("mason").setup(opts)

      -- handle opts.ensure_installed
      local registry = require("mason-registry")
      registry.refresh(function()
        if opts.ensure_installed == nil then
          return
        end

        for _, pkg_name in ipairs(opts.ensure_installed) do
          -- print("loading " .. pkg_name)
          local pkg = registry.get_package(pkg_name)
          if not pkg:is_installed() then
            pkg:install()
          end
        end
      end)
    end,
    cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
  },
}
