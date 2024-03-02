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
      -- vim.opt.fillchars = "diff:╱"
      vim.opt.fillchars = "diff:░"

      require("diffview").setup({
        -- file_panel = {
        --   win_config = {
        --     position = "bottom",
        --   },
        -- },
        view = {
          merge_tool = {
            disable_diagnostics = false, -- TODO: evaluate whether this actually shows diagnostics during review...
          },
        },
        enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
        hooks = {
          -- do not fold
          diff_buf_win_enter = function()
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

  {
    "f-person/git-blame.nvim",
    keys = {
      -- toggle needs to be called twice; https://github.com/f-person/git-blame.nvim/issues/16
      { "<leader>gbe", ":GitBlameEnable<CR>", desc = "Blame line (enable)" },
      { "<leader>gbd", ":GitBlameDisable<CR>", desc = "Blame line (disable)" },
      { "<leader>gbs", ":GitBlameCopySHA<CR>", desc = "Copy SHA" },
      { "<leader>gbc", ":GitBlameCopyCommitURL<CR>", desc = "Copy commit URL" },
      { "<leader>gbf", ":GitBlameCopyFileURL<CR>", desc = "Copy file URL" },
    },
  },

  {
    "topaxi/gh-actions.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    build = "make",
    cmd = "GhActions",
    keys = {
      { "<leader>ga", "<cmd>GhActions<cr>", desc = "Open Github Actions" },
    },
    -- optional, you can also install and use `yq` instead.
    config = function(_, opts)
      require("gh-actions").setup(opts)
    end,
    opts = {},
  },

  {
    "pwntester/octo.nvim",
    enabled = true,
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("octo").setup()
    end,
  },
}
