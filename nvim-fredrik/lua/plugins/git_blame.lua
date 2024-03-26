return {
  {
    "f-person/git-blame.nvim",
    event = "VeryLazy",
    keys = require("config.keymaps").setup_git_blame_keymaps(),
  },
}
