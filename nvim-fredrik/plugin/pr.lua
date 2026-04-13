require("lazyload").on_vim_enter(function()
  local dev = require("dev")

  vim.pack.add({
    { src = dev.prefer_local("~/code/public/pr.nvim", "https://github.com/fredrikaverpil/pr.nvim") },
  })

  require("pr").setup({})

  vim.keymap.set("n", "<leader>gbv", function()
    require("pr").view()
  end, { desc = "View PR in browser" })
end)
