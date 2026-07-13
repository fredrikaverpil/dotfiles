require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/CRAG666/code_runner.nvim" },
  })

  require("code_runner").setup({
    focus = false,
    filetype = {
      elixir = { "elixir" },
      go = { "go run" },
      typescript = { "deno run -A" },
      zig = { "zig run" },
    },
  })

  vim.keymap.set("n", "<leader>r", "<cmd>RunFile<CR>", { desc = "Run file" })
end)
