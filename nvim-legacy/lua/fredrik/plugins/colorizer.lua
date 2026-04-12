return {
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    enabled = false, -- adds in colors into e.g. Claude Code CLI and messes up stuff
    opts = {},
  },
}
