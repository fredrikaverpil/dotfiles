require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "templ",
    callback = function()
      vim.opt_local.expandtab = false
    end,
  })
end)
