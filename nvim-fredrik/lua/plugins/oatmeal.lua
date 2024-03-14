return {
  {
    -- help:
    -- /modellist
    -- /model  <model name from model list>
    -- /replace <number from code suggestion>
    -- exit with CTRL+C
    "dustinblackman/oatmeal.nvim",
    cmd = { "Oatmeal" },
    keys = {
      { "<leader>om", mode = "n", desc = "Start Oatmeal session" },
    },
    opts = {
      backend = "ollama",
      model = "codellama:latest",
    },
  },
}
