-- This is the local .lazy.lua for your per-project settings.
-- For more information, see nvim-lazyvim/lua/plugins/lazyrc.lua

-- usage example:
--
-- cd projectx
-- ln -s ~/code/dotfiles/templates/.lazy.lua .lazy.lua

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
    end,
  },
}
