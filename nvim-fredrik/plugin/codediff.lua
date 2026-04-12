require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/esmuellert/codediff.nvim", name = "codediff.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim", name = "nui.nvim" },
  })

  require("codediff").setup({
    explorer = {
      view_mode = "tree",
      file_filter = {
        ignore = { "*.pb.go" },
      },
      initial_focus = "modified",
    },
    history = {
      initial_focus = "modified",
    },
    keymaps = {
      view = {
        next_hunk = "]c",
        prev_hunk = "[c",
        next_file = "<Tab>",
        prev_file = "<S-Tab>",
      },
      explorer = {
        select = "<CR>",
        hover = "K",
        refresh = "R",
      },
    },
  })

  vim.keymap.set("n", "<leader>gdt", function()
    vim.cmd(":CodeDiff")
  end, { desc = "Diff this" })
  vim.keymap.set("n", "<leader>gdh", function()
    vim.cmd(":CodeDiff history %")
  end, { desc = "File history" })
  vim.keymap.set("n", "<leader>gdH", function()
    vim.cmd(":CodeDiff history")
  end, { desc = "Repo history" })
  vim.keymap.set("n", "<leader>gdd", function()
    vim.cmd(":CodeDiff " .. require("git").get_default_branch())
  end, { desc = "Diff against default branch" })
  vim.keymap.set("n", "<leader>gdr", function()
    vim.cmd(":CodeDiff " .. require("git").get_pr_merge_base())
  end, { desc = "Review current PR (GitHub-style)" })
  vim.keymap.set("n", "<leader>gdR", function()
    vim.cmd(":CodeDiff history " .. require("git").get_pr_merge_base() .. "...HEAD --reverse")
  end, { desc = "Review current PR (per commit)" })
end)
