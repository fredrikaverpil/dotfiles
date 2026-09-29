require("lazyload").on_vim_enter(function()
  -- Load disabled; enable on demand via the toggle keymap.
  vim.g.gitblame_enabled = false

  vim.pack.add({
    { src = "https://github.com/f-person/git-blame.nvim" },
  })

  vim.keymap.set("n", "<leader>gbl", "<cmd>GitBlameToggle<CR>", { desc = "Blame line (toggle)", silent = true })
  vim.keymap.set("n", "<leader>gbs", "<cmd>GitBlameCopySHA<CR>", { desc = "Copy SHA", silent = true })
  vim.keymap.set("n", "<leader>gbc", "<cmd>GitBlameCopyCommitURL<CR>", { desc = "Copy commit URL", silent = true })
  vim.keymap.set("n", "<leader>gbf", "<cmd>GitBlameCopyFileURL<CR>", { desc = "Copy file URL", silent = true })
  vim.keymap.set("n", "<leader>gbo", "<cmd>GitBlameOpenFileURL<CR>", { desc = "Open file URL", silent = true })
end)
