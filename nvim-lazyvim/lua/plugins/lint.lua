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

        -- markdown
        "vale",

        -- see lazy.lua for LazyVim extras
      }

      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, ensure_installed)
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
        markdown = { "vale" },
      }
    end,
  },
}
