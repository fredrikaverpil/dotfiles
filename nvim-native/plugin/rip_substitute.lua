-- rip-substitute: regex search and replace with live preview.

vim.pack.add({
  { src = "https://github.com/chrisgrieser/nvim-rip-substitute" },
})

vim.keymap.set({ "n", "x" }, "<leader>sR", function()
  require("rip-substitute").sub()
end, { desc = "Search replace (rip-substitute)" })
