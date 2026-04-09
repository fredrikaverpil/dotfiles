vim.pack.add({
  { src = "https://github.com/f-person/git-blame.nvim" },
})

-- Disable at startup.
vim.cmd(":GitBlameToggle")

vim.keymap.set("n", "<leader>gbl", ":GitBlameToggle<CR>", { desc = "Blame line (toggle)", silent = true })
vim.keymap.set("n", "<leader>gbs", ":GitBlameCopySHA<CR>", { desc = "Copy SHA", silent = true })
vim.keymap.set("n", "<leader>gbc", ":GitBlameCopyCommitURL<CR>", { desc = "Copy commit URL", silent = true })
vim.keymap.set("n", "<leader>gbf", ":GitBlameCopyFileURL<CR>", { desc = "Copy file URL", silent = true })
vim.keymap.set("n", "<leader>gbo", ":GitBlameOpenFileURL<CR>", { desc = "Open file URL", silent = true })
