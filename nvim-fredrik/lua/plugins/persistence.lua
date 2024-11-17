return {

  {
    "folke/persistence.nvim",
    enabled = false,
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {},
    config = function(_, opts)
      -- restore only some things from the last session, to avoid restoring e.g. blank buffers
      vim.opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,terminal"
      require("persistence").setup(opts)
    end,
  },
}
