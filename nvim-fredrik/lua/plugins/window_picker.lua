return {
  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    lazy = true,
    event = "VeryLazy",
    version = "*",
    opts = {
      hint = "floating-big-letter",
      filter_rules = {
        include_current_win = false,
        autoselect_one = true,
        -- filter using buffer options
        bo = {
          -- if the file type is one of following, the window will be ignored
          filetype = { "neo-tree", "neo-tree-popup", "notify" },
          -- if the buffer type is one of following, the window will be ignored
          buftype = { "terminal", "quickfix" },
        },
      },
    },
    config = function(_, opts)
      require("window-picker").setup(opts)
    end,
  },
}
