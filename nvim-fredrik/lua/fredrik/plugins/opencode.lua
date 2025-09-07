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

      -- Listen for opencode events
      vim.api.nvim_create_autocmd("User", {
        pattern = "OpencodeEvent",
        callback = function(args)
          -- See the available event types and their properties
          vim.notify(vim.inspect(args.data), vim.log.levels.DEBUG)
          -- Do something interesting, like show a notification when opencode finishes responding
          if args.data.type == "session.idle" then
            vim.notify("opencode finished responding", vim.log.levels.INFO)
          end
        end,
      })
    end,
  -- stylua: ignore
  keys = require("fredrik.config.keymaps").setup_opencode_keymaps(),
  },
}
