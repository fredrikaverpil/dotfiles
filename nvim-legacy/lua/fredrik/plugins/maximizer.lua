return {
  {
    "szw/vim-maximizer",
    cmds = { "MaximizerToggle" },
    keys = require("fredrik.config.keymaps").setup_maximizer_keymaps(),
  },
}
