return {
  {
    -- NOTE: jump between diffs with ]c and [c (vim built in), see :h jumpto-diffs
    "sindrets/diffview.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-tree/nvim-web-devicons" },
    },
    lazy = false,
    config = function()
      vim.opt.fillchars = "diff:╱"
      -- vim.opt.fillchars = "diff:░"
      -- vim.opt.fillchars = "diff:·"

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
    keys = {
      -- use [c and [c to navigate diffs (vim built in), see :h jumpto-diffs
      -- use ]x and [x to navigate conflicts
      { "<leader>gdc", ":DiffviewOpen origin/main...HEAD", desc = "Compare commits" },
      { "<leader>gdd", ":DiffviewClose<CR>", desc = "Close Diffview tab" },
      { "<leader>gdh", ":DiffviewFileHistory %<CR>", desc = "File history" },
      { "<leader>gdH", ":DiffviewFileHistory<CR>", desc = "Repo history" },
      { "<leader>gdm", ":DiffviewOpen<CR>", desc = "Solve merge conflicts" },
      { "<leader>gdo", ":DiffviewOpen main", desc = "DiffviewOpen" },
      { "<leader>gdp", ":DiffviewOpen origin/main...HEAD --imply-local", desc = "Review current PR" },
      {
        "<leader>gdP",
        ":DiffviewFileHistory --range=origin/main...HEAD --right-only --no-merges",
        desc = "Review current PR (per commit)",
      },
    },
  },
}
