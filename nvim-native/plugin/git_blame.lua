-- git-blame: inline git blame annotations.

vim.pack.add({
  { src = "https://github.com/f-person/git-blame.nvim" },
})

-- Disable at startup.
vim.cmd(":GitBlameToggle")

local nmap = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
end

nmap("<leader>gbl", ":GitBlameToggle<CR>", "Blame line (toggle)")
nmap("<leader>gbs", ":GitBlameCopySHA<CR>", "Copy SHA")
nmap("<leader>gbc", ":GitBlameCopyCommitURL<CR>", "Copy commit URL")
nmap("<leader>gbf", ":GitBlameCopyFileURL<CR>", "Copy file URL")
nmap("<leader>gbo", ":GitBlameOpenFileURL<CR>", "Open file URL")
