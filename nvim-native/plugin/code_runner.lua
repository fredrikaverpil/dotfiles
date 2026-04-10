vim.pack.add({
  { src = "https://github.com/CRAG666/code_runner.nvim" },
})

require("lazyload").on_vim_enter(function()
  require("code_runner").setup({
    focus = false,
    filetype = {
      go = { "go run" },
      typescript = { "bun" },
      zig = { "zig run" },
    },
  })
end)

vim.keymap.set("n", "<leader>r", ":RunFile<CR>", { desc = "Run file" })
