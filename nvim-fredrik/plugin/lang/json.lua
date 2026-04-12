require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "json", "json5", "jsonc" },
    callback = function()
      vim.opt_local.conceallevel = 0
    end,
  })
end)
