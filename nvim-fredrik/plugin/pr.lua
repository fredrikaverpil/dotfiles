require("lazyload").on_vim_enter(function()
  require("dev").load_local("~/code/public/pr.nvim")
  vim.pack.add({
    -- { src = "https://github.com/fredrikaverpil/pr.nvim" },
  })

  require("pr").setup({})

  vim.keymap.set("n", "<leader>gbv", function()
    require("pr").view()
  end, { desc = "View PR in browser" })
end)
