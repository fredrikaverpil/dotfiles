return {

  {
    "y3owk1n/cmd.nvim",
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {},
    config = function()
      require("cmd").setup({
        progress_notifier = {
          adapter = require("cmd").builtins.spinner_adapters.snacks,
        },
      })
    end,
    cmds = { "Cmd" },
  },
}
