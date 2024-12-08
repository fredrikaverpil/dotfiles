return {
  {
    "fredrikaverpil/pr.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    dir = "~/code/public/pr.nvim",
    opts = {},
    keys = {
      {
        "<leader>o",
        function()
          require("pr").open()
        end,
        desc = "Open PR",
      },
    },
  },
}
