-- Lua: formatter.
-- Runs after plugin/ is fully sourced (after/plugin/ loading order).

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
  },
})
