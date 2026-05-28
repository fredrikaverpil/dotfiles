require("lang").register("templ", {
  servers = { "templ" },
  mason = { "templ" },
})

require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("templ-opts", { clear = true }),
    pattern = "templ",
    callback = function()
      vim.opt_local.expandtab = false
    end,
  })
end)
