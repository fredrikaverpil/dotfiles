if Config.use_diffview then
  require("lazyload").on_vim_enter(function()
    vim.pack.add({
      { src = "https://github.com/dlyongemallo/diffview.nvim", version = vim.version.range("*") },
    })

    require("diffview").setup({

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
    })

    -- local keys = {
    --   -- use [c and [c to navigate diffs (vim built in), see :h jumpto-diffs
    --   -- use ]x and [x to navigate conflicts
    --
    --   { "<leader>gdx", ":DiffviewOpen<CR>", desc = "DiffviewOpen this" },
    --   { "<leader>gdq", ":DiffviewClose<CR>", desc = "Close Diffview tab" },
    --   { "<leader>gdh", ":DiffviewFileHistory %<CR>", desc = "File history" },
    --   { "<leader>gdH", ":DiffviewFileHistory<CR>", desc = "Repo history" },
    --   { "<leader>gdm", ":DiffviewOpen<CR>", desc = "Solve merge conflicts" },
    --   {
    --     "<leader>gdd",
    --     ":DiffviewOpen " .. require("fredrik.utils.git").get_default_branch() .. "<cr>",
    --     desc = "DiffviewOpen against default branch",
    --   },
    --   {
    --     "<leader>gdr",
    --     function()
    --       local default_branch = require("fredrik.utils.git").get_default_branch()
    --       vim.cmd(":DiffviewOpen origin/" .. default_branch .. "...HEAD --imply-local")
    --     end,
    --     desc = "Review current PR",
    --   },
    --   {
    --     "<leader>gdR",
    --     function()
    --       local default_branch = require("fredrik.utils.git").get_default_branch()
    --       return vim.cmd(
    --         ":DiffviewFileHistory --range=origin/" .. default_branch .. "...HEAD --right-only --no-merges --reverse"
    --       )
    --     end,
    --     desc = "Review current PR (per commit)",
    --   },
    -- }

    vim.keymap.set("n", "<leader>gdt", function()
      vim.cmd(":DiffviewOpen")
    end, { desc = "Diff this" })
    vim.keymap.set("n", "<leader>gdh", function()
      vim.cmd(":DiffviewFileHistory %")
    end, { desc = "File history" })
    vim.keymap.set("n", "<leader>gdH", function()
      vim.cmd(":DiffviewFileHistory")
    end, { desc = "Repo history" })
    vim.keymap.set("n", "<leader>gdd", function()
      vim.cmd(":DiffviewOpen " .. require("git").get_default_branch())
    end, { desc = "Diff against default branch" })
    vim.keymap.set("n", "<leader>gdr", function()
      vim.cmd(":DiffviewOpen origin/" .. require("git").get_pr_merge_base() .. " ...HEAD --imply-local")
    end, { desc = "Review current PR (GitHub-style)" })
    vim.keymap.set("n", "<leader>gdR", function()
      vim.cmd(
        ":DiffviewOpen --range=origin/"
          .. require("git").get_pr_merge_base()
          .. "...HEAD --right-only --no-merges --reverse"
      )
    end, { desc = "Review current PR (per commit)" })
  end)
end
