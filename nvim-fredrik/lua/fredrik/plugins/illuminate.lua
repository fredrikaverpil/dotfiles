return {
  {
    "RRethy/vim-illuminate",
    lazy = true,
    event = "BufReadPost",
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },
}
