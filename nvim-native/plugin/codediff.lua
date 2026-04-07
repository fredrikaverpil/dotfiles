-- codediff: side-by-side git diff viewer with explorer.

vim.pack.add({
  { src = "https://github.com/esmuellert/codediff.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
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

local git = require("git")
local nmap = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

nmap("<leader>gdt", ":CodeDiff<CR>", "Diff this")
nmap("<leader>gdh", ":CodeDiff history %<CR>", "File history")
nmap("<leader>gdH", ":CodeDiff history<CR>", "Repo history")
nmap("<leader>gdd", function()
  vim.cmd(":CodeDiff " .. git.get_default_branch())
end, "Diff against default branch")
nmap("<leader>gdr", function()
  vim.cmd(":CodeDiff " .. git.get_pr_merge_base())
end, "Review current PR (GitHub-style)")
nmap("<leader>gdR", function()
  vim.cmd(":CodeDiff history " .. git.get_pr_merge_base() .. "...HEAD --reverse")
end, "Review current PR (per commit)")
