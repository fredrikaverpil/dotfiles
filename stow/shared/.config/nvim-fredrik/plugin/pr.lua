require("lazyload").on_vim_enter(function()
  -- Load from disk if checked out locally, otherwise from GitHub.
  if not require("dev").load_local("~/code/public/github.com/fredrikaverpil/pr.nvim") then
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/pr.nvim" },
    })
  end

  require("pr").setup({})

  vim.keymap.set("n", "<leader>gbv", function()
    require("pr").view()
  end, { desc = "View PR in browser" })
end)
