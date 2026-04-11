-- Registered on disk now, loaded on first keymap press.
local packages = {
  { src = "https://github.com/esmuellert/codediff.nvim", name = "codediff.nvim" },
  { src = "https://github.com/MunifTanjim/nui.nvim", name = "nui.nvim" },
}
vim.pack.add(packages, { load = function() end })

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  for _, p in ipairs(packages) do
    vim.cmd.packadd(p.name)
  end

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

vim.keymap.set("n", "<leader>gdt", function()
  init()
  vim.cmd(":CodeDiff")
end, { desc = "Diff this" })
vim.keymap.set("n", "<leader>gdh", function()
  init()
  vim.cmd(":CodeDiff history %")
end, { desc = "File history" })
vim.keymap.set("n", "<leader>gdH", function()
  init()
  vim.cmd(":CodeDiff history")
end, { desc = "Repo history" })
vim.keymap.set("n", "<leader>gdd", function()
  init()
  vim.cmd(":CodeDiff " .. require("git").get_default_branch())
end, { desc = "Diff against default branch" })
vim.keymap.set("n", "<leader>gdr", function()
  init()
  vim.cmd(":CodeDiff " .. require("git").get_pr_merge_base())
end, { desc = "Review current PR (GitHub-style)" })
vim.keymap.set("n", "<leader>gdR", function()
  init()
  vim.cmd(":CodeDiff history " .. require("git").get_pr_merge_base() .. "...HEAD --reverse")
end, { desc = "Review current PR (per commit)" })
