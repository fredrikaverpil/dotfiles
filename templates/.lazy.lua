return {

  {
    "stevearc/conform.nvim",
    -- https://github.com/stevearc/conform.nvim
    enabled = true,
    opts = function(_, opts)
      local formatters = require("conform.formatters")

      vim.api.nvim_echo({ { "Using custom import ordering for Ingrid.", "None" } }, false, {})
      -- https://github.com/stevearc/conform.nvim/blob/master/lua/conform/formatters/gci.lua
      formatters.gci.args = {
        "write",
        "-s",
        "standard",
        "-s",
        "default",
        "-s",
        "Prefix(github.com/shipwallet)",
        "--skip-generated",
        "--skip-vendor",
        "$FILENAME",
      }

      -- NOTE: conform.nvim can use a sub-list to run only the first available formatter (see docs)

      -- review opts.formatters_by_ft by uncommenting the below
      -- vim.api.nvim_echo(
      --   { { "opts.formatters_by_ft", "None" }, { vim.inspect(opts.formatters_by_ft), "None" } },
      --   false,
      --   {}
      -- )
    end,
  },
}
