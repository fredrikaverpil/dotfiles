require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/nvzone/showkeys" },
  })

  vim.keymap.set("n", "<leader>uk", ":ShowkeysToggle<CR>", { desc = "Toggle showkeys", silent = true })
end)
