return {
  {
    "CRAG666/code_runner.nvim",
    lazy = true,
    opts = {
      focus = false,
    },
    config = function(_, opts)
      require("code_runner").setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_coderunner_keymaps(),
    cmd = { "RunFile" },
  },
}
