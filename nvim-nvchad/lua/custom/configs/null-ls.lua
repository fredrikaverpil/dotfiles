-- custom/configs/null-ls.lua
-- https://nvchad.com/docs/config/format_lint

local null_ls = require "null-ls"

local formatting = null_ls.builtins.formatting
local lint = null_ls.builtins.diagnostics

local sources = {
   formatting.prettier,
   formatting.stylua,
   formatting.black,
   lint.shellcheck,
   lint.ruff,
}

null_ls.setup {
   debug = true,
   sources = sources,
}
