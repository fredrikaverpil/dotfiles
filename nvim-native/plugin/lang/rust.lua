vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("native-rust-opts", { clear = true }),
  pattern = "rust",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.shiftwidth = 4
  end,
})
