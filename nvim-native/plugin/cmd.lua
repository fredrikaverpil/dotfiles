-- cmd.nvim: run shell commands with progress notifications.

vim.pack.add({
  { src = "https://github.com/y3owk1n/cmd.nvim" },
})

require("cmd").setup({
  progress_notifier = {
    adapter = require("cmd").builtins.spinner_adapters.snacks,
  },
})
