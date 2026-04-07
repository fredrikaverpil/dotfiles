-- Code runner via code_runner.nvim.

vim.pack.add({
  { src = "https://github.com/CRAG666/code_runner.nvim" },
})

require("code_runner").setup({ focus = false })

vim.keymap.set("n", "<leader>r", ":RunFile<CR>", { desc = "Run file" })
