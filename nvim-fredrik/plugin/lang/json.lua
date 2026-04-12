vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("native-json-opts", { clear = true }),
  pattern = { "json", "json5", "jsonc" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})
