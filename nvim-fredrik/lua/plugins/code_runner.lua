return {
  {
    "CRAG666/code_runner.nvim",
    event = "VeryLazy",
    config = function()
      require("code_runner").setup({
        focus = false,

        filetype = {
          go = {
            "go run",
          },
        },
      })
    end,

    require("config.keymaps").setup_coderunner_keymaps(),
  },
}
