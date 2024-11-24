return {
  "chrisgrieser/nvim-rip-substitute",
  lazy = true,
  keys = require("config.keymaps").setup_rip_substitute_keymaps(),
  cmd = { "RipSubstitute" },
}
