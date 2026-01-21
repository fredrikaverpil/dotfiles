return {

  {
    "nvim-mini/mini.pick",
    enabled = false,
    version = "*",
    opts = {
      options = {
        -- Whether to cache matches (more speed and memory on repeated prompts)
        use_cache = true,
      },
    },
    cmd = { "Pick" },
    keys = require("fredrik.config.keymaps").setup_mini_pick_keymaps(),
  },
}
