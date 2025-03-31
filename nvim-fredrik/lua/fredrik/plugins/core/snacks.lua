return {
  {
    "folke/snacks.nvim",
    dependencies = {
      --  "folke/persistence.nvim",
      {
        "nvim-lualine/lualine.nvim",
        opts = {
          options = {
            disabled_filetypes = { "snacks_dashboard" },
          },
        },
        opts_extend = {
          "options.disabled_filetypes",
        },
      },
      { "folke/trouble.nvim" },
      { "folke/todo-comments.nvim" },
    },
    priority = 1000,
    lazy = false,

    ---@type snacks.Config
    opts = {
      styles = {
        notification_history = {
          relative = "editor",
          width = 0.9,
          height = 0.9,
        },
      },

      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },

      image = { enabled = true },

      indent = {
        enabled = true,
        priority = 1,
        animate = {
          enabled = false,
          style = "out",
          easing = "linear",
          duration = {
            step = 20, -- ms per step
            total = 500, -- maximum duration
          },
        },
      },

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

      notifier = { enabled = true, timeout = 2000 },

      picker = {
        enabled = true,
        actions = require("trouble.sources.snacks").actions,
        sources = {
          files = {
            hidden = true, -- NOTE: toggle with alt+h
            ignored = false, -- NOTE: toggle with alt+h
          },
        },
        win = {
          input = {
            keys = {
              ["<c-t>"] = {
                "trouble_open",
                mode = { "n", "i" },
              },
            },
          },
        },
      },

      explorer = {
        enabled = true,
      },

      quickfile = { enabled = true },

      statuscolumn = { enabled = true },

      terminal = { enabled = true },

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
        win = {
          backdrop = {
            transparent = false,
          },
        },
      },
    },
    keys = function()
      ---@type table[table]
      local snacks_keymaps = require("fredrik.config.keymaps").setup_snacks_keymaps()
      ---@type table[table]
      local terminal_keymaps = require("fredrik.config.keymaps").setup_terminal_keymaps()

      local merged_keymaps = {}
      for _, keymap in ipairs(snacks_keymaps) do
        table.insert(merged_keymaps, keymap)
      end
      for _, keymap in ipairs(terminal_keymaps) do
        table.insert(merged_keymaps, keymap)
      end
      return merged_keymaps
    end,
  },
}
