local registry = require("registry")

vim.pack.add({
  { src = "https://github.com/CRAG666/code_runner.nvim" },
})

require("code_runner").setup({
  focus = false,
  filetype = registry.code_runner,
})

vim.keymap.set("n", "<leader>r", ":RunFile<CR>", { desc = "Run file" })
