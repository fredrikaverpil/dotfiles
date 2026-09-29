require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/sindrets/winshift.nvim" },
  })

  vim.keymap.set("n", "<leader>ww", "<cmd>WinShift<CR>", { desc = "WinShift (shift + arrows)" })
end)
