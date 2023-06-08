return {

  -- diffview
  {
    "sindrets/diffview.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
    },
    lazy = false,
    config = function()
      -- vim.opt.fillchars = "diff:╱"
      vim.opt.fillchars = "diff:░"

      require("diffview").setup({
        enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
      })
    end,
    keys = {
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

  -- git-blame
  {
    "f-person/git-blame.nvim",
    keys = {
      { "<leader>gbb", ":GitBlameToggle<CR>", desc = "Blame (toggle)" },
      { "<leader>gbs", ":GitBlameCopySHA<CR>", desc = "Copy SHA" },
      { "<leader>gbc", ":GitBlameCopyCommitURL<CR>", desc = "Copy commit URL" },
      { "<leader>gbf", ":GitBlameCopyFileURL<CR>", desc = "Copy file URL" },
    },
  },

  -- octo
  {
    "pwntester/octo.nvim",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "kyazdani42/nvim-web-devicons",
    },
    config = function()
      require("octo").setup()
    end,
  },
}
