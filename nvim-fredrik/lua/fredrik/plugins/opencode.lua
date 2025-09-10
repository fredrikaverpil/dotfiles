return {

  {
    "NickvanDyke/opencode.nvim",
    lazy = true,
    dependencies = {
      {
        "folke/snacks.nvim",
        opts = {
          -- Recommended for better prompt input, and required to use `opencode.nvim`'s embedded terminal — otherwise optional
          input = { enabled = true },
        },
      },
    },
    config = function()
      -- `opencode.nvim` passes options via a global variable instead of `setup()` for faster startup
      vim.g.opencode_opts = {
        -- Your configuration, if any - see:
        -- https://github.com/NickvanDyke/opencode.nvim/blob/main/lua/opencode/config.lua
      }
      -- Required for `opts.auto_reload`
      -- NOTE: this is already set in `fredrik/config/options.lua`
      -- vim.opt.autoread = true
    end,
  -- stylua: ignore
  keys = require("fredrik.config.keymaps").setup_opencode_keymaps(),
  },
}
