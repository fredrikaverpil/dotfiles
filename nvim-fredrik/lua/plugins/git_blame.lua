return {
  {
    "f-person/git-blame.nvim",
    lazy = true,
    config = function()
      vim.cmd(":GitBlameToggle") -- disable at startup
    end,
    keys = require("config.keymaps").setup_git_blame_keymaps(),
  },
}
