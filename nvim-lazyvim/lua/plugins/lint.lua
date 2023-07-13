return {

  {
    "williamboman/mason.nvim",

    opts = function(_, opts)
      local ensure_installed = {
        -- python
        "mypy",

        -- lua
        "luacheck",

        -- shell
        "shellcheck",

        -- yaml
        "yamllint",

        -- sql
        "sqlfluff",

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
        python = { "mypy" },
        lua = { "luacheck" },
        yaml = { "yamllint" },
        sh = { "shellcheck" },
        sql = { "sqlfluff" },
      }
    end,
  },
}
