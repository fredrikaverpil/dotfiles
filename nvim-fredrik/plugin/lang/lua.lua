require("lang").register("lua", {})

require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("lua-opts", { clear = true }),
    pattern = { "lua" },
    callback = function()
      vim.opt_local.tabstop = 2
      vim.opt_local.softtabstop = 2
      vim.opt_local.shiftwidth = 2
      vim.opt_local.expandtab = true
    end,
  })

  vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim", version = vim.version.range("*") },
    { src = "https://github.com/Bilal2453/luvit-meta" }, -- vim.uv typings
  })

  require("lazydev").setup({
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "snacks.nvim", words = { "Snacks" } },
      "neotest",
      "plenary",
    },
  })
end)
