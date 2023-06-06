return {
  {
    "CRAG666/code_runner.nvim",
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
    keys = { { "<leader>rf", "<cmd>RunFile term<cr>", desc = "Run file" } },
  },
}
