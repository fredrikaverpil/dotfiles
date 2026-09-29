require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/y3owk1n/cmd.nvim" },
  })

  require("cmd").setup({
    progress_notifier = {
      adapter = require("cmd").builtins.spinner_adapters.snacks,
    },
  })
end)
