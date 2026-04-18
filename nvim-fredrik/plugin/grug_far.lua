require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/MagicDuck/grug-far.nvim" },
  })

  require("grug-far").setup({
    prefills = {
      filesFilter = "*.*",
    },
  })

  vim.keymap.set("n", "<leader>sr", "<cmd>GrugFar<cr>", { desc = "Search and replace (grug-far)" })
  vim.keymap.set(
    "v",
    "<leader>sr",
    "<cmd>'<,'>GrugFarWithin<cr>",
    { desc = "Search and replace in selection (grug-far)" }
  )
end)
