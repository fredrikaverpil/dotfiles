vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("native-templ-opts", { clear = true }),
  pattern = "templ",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})
