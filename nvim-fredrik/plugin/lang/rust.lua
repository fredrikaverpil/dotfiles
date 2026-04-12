require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    callback = function()
      vim.opt_local.tabstop = 4
      vim.opt_local.softtabstop = 4
      vim.opt_local.shiftwidth = 4
    end,
  })
end)
