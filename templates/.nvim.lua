-- This is the local .nvim.lua for your per-project settings.
-- For more information, run :help exrc

-- Override the configuration for conform.nvim
-- In this case, override the Python formatters.
local conform = require("conform")
conform.setup({
  formatters_by_ft = {
    python = { "isort", "black" },
  },
})
