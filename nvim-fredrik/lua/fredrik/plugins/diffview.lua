return {
  {
    -- NOTE: jump between diffs with ]c and [c (vim built in), see :h jumpto-diffs
    "sindrets/diffview.nvim",
    lazy = true,
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      -- icons supported via mini-icons.lua
    },

    opts = {

      -- file_panel = {
      --   win_config = {
      --     position = "bottom",
      --   },
      -- },

      default = {
        disable_diagnostics = false,
      },
      view = {
        merge_tool = {
          disable_diagnostics = false,
          winbar_info = true,
        },
      },
      enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
      hooks = {
        -- do not fold
        diff_buf_win_enter = function(bufnr)
          vim.opt_local.foldenable = false
        end,

        -- TODO: jump to first diff: https://github.com/sindrets/diffview.nvim/issues/440
        -- TODO: enable diagnostics in diffview
      },
    },

    config = function(_, opts)
      local actions = require("diffview.actions")

      require("diffview").setup(opts)
    end,
    keys = require("fredrik.config.keymaps").setup_diffview_keymaps(),
  },
}
