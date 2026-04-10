vim.pack.add({
  { src = "https://github.com/CRAG666/code_runner.nvim" },
})

require("startup").on_vim_enter(function()
  local merge = require("merge")
  local registry = require("registry")

  local opts = { focus = false }
  require("code_runner").setup(merge(opts, registry.code_runner.opts or {}))
end)

vim.keymap.set("n", "<leader>r", ":RunFile<CR>", { desc = "Run file" })
