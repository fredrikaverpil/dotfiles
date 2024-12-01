return {

  {
    "echasnovski/mini.indentscope",
    lazy = true,
    event = "BufReadPost",
    version = "*",
    opts = {
      draw = {
        delay = 0,
      },
      -- symbol = "▏",
      symbol = "│",
      options = { try_as_border = true },
    },
    config = function(_, opts)
      require("mini.indentscope").setup(opts)
    end,
  },
}
