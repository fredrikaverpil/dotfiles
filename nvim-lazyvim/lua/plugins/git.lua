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
      {
        "<leader>gdd",
        function()
          vim.cmd("DiffviewClose")
        end,
        desc = "Close Diffview tab",
      },
      {
        "<leader>gdc",
        ":DiffviewOpen origin/main...HEAD",
        { desc = "Compare commits" },
      },
      {
        "<leader>gdf",
        function()
          vim.cmd("DiffviewFileHistory %")
        end,
        desc = "File history",
      },
      {
        "<leader>gdr",
        function()
          vim.cmd("DiffviewFileHistory")
        end,
        desc = "Repo history",
      },
      {
        "<leader>gdm",
        function()
          vim.cmd("DiffviewOpen main")
        end,
        desc = "DiffviewOpen main",
      },
      {
        "<leader>gdn",
        function()
          vim.cmd("DiffviewOpen master")
        end,
        desc = "DiffviewOpen master",
      },
    },
  },

  -- git-blame
  {
    "f-person/git-blame.nvim",
    keys = {
      {
        "<leader>gbb",
        function()
          vim.cmd("GitBlameToggle")
        end,
        desc = "Blame (toggle)",
      },
      {
        "<leader>gbs",
        function()
          vim.cmd("GitBlameCopySHA")
        end,
        desc = "Copy SHA",
      },
      {
        "<leader>gbc",
        function()
          vim.cmd("GitBlameCopyCommitURL")
        end,
        desc = "Copy commit URL",
      },
      {
        "<leader>gbf",
        function()
          vim.cmd("GitBlameCopyFileURL")
        end,
        desc = "Copy file URL",
      },
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
