require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/CRAG666/code_runner.nvim" },
  })

  require("code_runner").setup({
    focus = false,
    filetype = require("lang").spec().code_runner,
  })

  vim.keymap.set("n", "<leader>r", "<cmd>RunFile<CR>", { desc = "Run file" })
end)
