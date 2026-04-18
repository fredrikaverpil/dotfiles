require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/chrishrb/gx.nvim" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
  })

  require("gx").setup({})

  vim.keymap.set({ "n", "x" }, "gx", "<cmd>Browse<cr>", { desc = "Browse URL" })
end)
