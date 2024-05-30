return {
  {
    "RRethy/vim-illuminate",
    event = "VeryLazy",
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },
}
