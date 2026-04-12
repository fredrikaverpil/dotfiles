return {

  {
    "nvim-mini/mini.pick",
    enabled = true,
    version = "*",
    opts = {
      options = {
        -- Whether to cache matches (more speed and memory on repeated prompts)
        use_cache = true,
      },
    },
    cmd = { "Pick" },
    -- NOTE: disabled <leader> keymaps
    -- keys = require("fredrik.config.keymaps").setup_mini_pick_keymaps(),
  },
}
