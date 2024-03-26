return {
  {
    -- NOTE: jump between diffs with ]c and [c (vim built in), see :h jumpto-diffs
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-tree/nvim-web-devicons" },
    },
    config = function()
      local actions = require("diffview.actions")

      require("diffview").setup({
        -- file_panel = {
        --   win_config = {
        --     position = "bottom",
        --   },
        -- },
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
      })
    end,
    keys = require("config.keymaps").setup_diffview_keymaps(),
  },
}
