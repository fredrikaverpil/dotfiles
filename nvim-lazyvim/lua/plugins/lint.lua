return {

  {
    "williamboman/mason.nvim",

    opts = function(_, opts)
      local ensure_installed = {
        -- python
        "mypy",
        "black",

        -- lua
        "luacheck",

        -- shell
        "shellcheck",

        -- see lazy.lua for LazyVim extras
      }

      -- extend opts.ensure_installed
      for _, package in ipairs(ensure_installed) do
        table.insert(opts.ensure_installed, package)
      end
    end,
  },

  {
    -- NOTE: autocmd is required, see autocmds.lua
    "mfussenegger/nvim-lint",
    enabled = false, -- let's see what happens with null-ls and LazyVim
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        yaml = { "yamllint" },
        sh = { "shellcheck" },
        lua = { "luacheck" },
        python = { "mypy" },
      }
    end,
  },
}
