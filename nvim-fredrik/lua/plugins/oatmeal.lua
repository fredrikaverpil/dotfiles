return {
  {
    -- help:
    -- /modellist
    -- /model  <model name from model list>
    -- /replace <number from code suggestion>
    -- exit with CTRL+C
    "dustinblackman/oatmeal.nvim",
    cmd = { "Oatmeal" },
    opts = {
      backend = "ollama",
      model = "llama3:latest",
    },
    keys = require("config.keymaps").setup_oatmeal_keymaps(),
  },
}
