return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    ---@type snacks.Config
    opts = {
      styles = {
        notification_history = {
          width = 0.9,
          height = 0.9,
        },
      },
      notifier = { enabled = true, timeout = 2000 },
      statuscolumn = { enabled = true },
      indent = {
        enabled = true,
        animate = {
          enabled = vim.fn.has("nvim-0.10") == 1,
          style = "out",
          easing = "linear",
          duration = {
            step = 20, -- ms per step
            total = 500, -- maximum duration
          },
        },
      },

      -- special mode
      zen = {
        enabled = true,
        -- You can add any `Snacks.toggle` id here.
        -- Toggle state is restored when the window is closed.
        -- Toggle config options are NOT merged.
        ---@type table<string, boolean>
        toggles = {
          dim = false,
          git_signs = false,
          mini_diff_signs = false,
          diagnostics = true,
          -- inlay_hints = false,
        },
      },

      -- convenience
      quickfile = { enabled = true },

      -- integrations
      lazygit = {
        enabled = true,
        -- automatically configure lazygit to use the current colorscheme
        -- and integrate edit with the current neovim instance
        configure = true,

        config = {
          os = { editPreset = "nvim-remote" },
          gui = {
            -- set to an empty string "" to disable icons
            nerdFontsVersion = "3",
          },
          git = {
            overrideGpg = true,
          },
        },
      },
    },
    keys = require("fredrik.config.keymaps").setup_snacks_keymaps(),
  },
}
