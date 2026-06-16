require("lang").register("protobuf", {})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("proto-opts", { clear = true }),
  pattern = "proto",
  callback = function()
    vim.opt_local.expandtab = false
  end,
})
