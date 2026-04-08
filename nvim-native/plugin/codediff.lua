vim.pack.add({
  { src = "https://github.com/esmuellert/codediff.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },
})

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

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
end

local nmap = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

nmap("<leader>gdt", function()
  init()
  vim.cmd(":CodeDiff")
end, "Diff this")
nmap("<leader>gdh", function()
  init()
  vim.cmd(":CodeDiff history %")
end, "File history")
nmap("<leader>gdH", function()
  init()
  vim.cmd(":CodeDiff history")
end, "Repo history")
nmap("<leader>gdd", function()
  init()
  vim.cmd(":CodeDiff " .. require("git").get_default_branch())
end, "Diff against default branch")
nmap("<leader>gdr", function()
  init()
  vim.cmd(":CodeDiff " .. require("git").get_pr_merge_base())
end, "Review current PR (GitHub-style)")
nmap("<leader>gdR", function()
  init()
  vim.cmd(":CodeDiff history " .. require("git").get_pr_merge_base() .. "...HEAD --reverse")
end, "Review current PR (per commit)")
