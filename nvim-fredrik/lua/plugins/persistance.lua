return {

  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    opts = {
      -- NOTE: see options.lua for vim.opt.sessionoptions
    },
  },
}
