return {

  {
    "ibhagwan/fzf-lua",
    lazy = false,
    dependencies = {
      "folke/trouble.nvim",
    },
    config = function(_, opts)
      local config = require("fzf-lua.config")

      -- Quickfix
      config.defaults.keymap.fzf["ctrl-q"] = "select-all+accept"
      -- config.defaults.keymap.fzf["ctrl-u"] = "half-page-up"
      -- config.defaults.keymap.fzf["ctrl-d"] = "half-page-down"
      -- config.defaults.keymap.fzf["ctrl-x"] = "jump"
      -- config.defaults.keymap.fzf["ctrl-b"] = "preview-page-up"
      -- config.defaults.keymap.fzf["ctrl-f"] = "preview-page-down"
      config.defaults.keymap.builtin["<c-u>"] = "preview-page-up"
      config.defaults.keymap.builtin["<c-d>"] = "preview-page-down"

      config.defaults.actions.files["ctrl-t"] = require("trouble.sources.fzf").actions.open

      require("fzf-lua").setup(opts)
    end,
    cmd = { "FzfLua" },
    keys = require("fredrik.config.keymaps").setup_fzf_keymaps(),
  },
}
