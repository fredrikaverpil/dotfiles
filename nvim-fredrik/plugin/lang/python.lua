require("lang").register("python", {
  dap = {
    packs = {
      { src = "https://codeberg.org/mfussenegger/nvim-dap-python" },
    },
    setup = function()
      require("dap-python").setup("uv")
    end,
  },
})

require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("python-opts", { clear = true }),
    pattern = "python",
    callback = function()
      vim.opt_local.tabstop = 4
      vim.opt_local.softtabstop = 4
      vim.opt_local.shiftwidth = 4
    end,
  })
end)
