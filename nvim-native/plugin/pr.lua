require("dev").add({
  dev = "~/code/public/pr.nvim",
  fallback = function()
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/pr.nvim" },
    })
  end,
})

require("pr").setup({})

vim.keymap.set("n", "<leader>gbv", function()
  require("pr").view()
end, { desc = "View PR in browser" })
