vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "**/ghostty/config", "*.ghostty", "ghostty.conf" },
  callback = function()
    local buffer = vim.api.nvim_get_current_buf()

    vim.bo[buffer].filetype = "ghostty"

    vim.cmd.syntax("clear")

    vim.cmd([[
      syntax keyword GhosttyTodo contained TODO FIXME XXX BUG HACK NOTE WARNING
      syntax match GhosttyComment "#.*$" contains=GhosttyTodo oneline
      syntax match GhosttyKey "^\s*[a-zA-Z0-9-]\+" nextgroup=ghosttyEquals
      syntax match GhosttyEquals "\s*=\s*" contained nextgroup=ghosttyValue
      syntax match GhosttyValue "[^#\n]*" contained
    ]])

    vim.api.nvim_set_hl(0, "GhosttyComment", { link = "Comment" })
    vim.api.nvim_set_hl(0, "GhosttyTodo", { link = "Todo" })
    vim.api.nvim_set_hl(0, "GhosttyKey", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "GhosttyOperator", { link = "Operator" })
    vim.api.nvim_set_hl(0, "GhosttyValue", { link = "String" })
  end,
})

return {}
