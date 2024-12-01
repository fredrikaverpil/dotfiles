return {

  {
    "akinsho/bufferline.nvim",
    lazy = true,
    event = "VeryLazy",
    opts = {
      options = {
        mode = "tabs", -- only show tabpages instead of buffers
        always_show_bufferline = false,
      },
    },
  },
}
