vim.pack.add({
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
})

require("gitsigns").setup({})

local map = vim.keymap.set

-- Hunk navigation
map("n", "]h", function()
  if vim.wo.diff then
    return "]c"
  end
  vim.schedule(function()
    require("gitsigns").nav_hunk("next")
  end)
  return "<Ignore>"
end, { expr = true, desc = "Next hunk" })

map("n", "[h", function()
  if vim.wo.diff then
    return "[c"
  end
  vim.schedule(function()
    require("gitsigns").nav_hunk("prev")
  end)
  return "<Ignore>"
end, { expr = true, desc = "Prev hunk" })

-- Hunk actions
map({ "n", "v" }, "<leader>ghs", function()
  require("gitsigns").stage_hunk()
end, { desc = "Stage hunk" })

map({ "n", "v" }, "<leader>ghS", function()
  require("gitsigns").stage_buffer()
end, { desc = "Stage buffer" })

map("n", "<leader>ghr", function()
  require("gitsigns").reset_hunk()
end, { desc = "Reset hunk" })

map({ "n", "v" }, "<leader>ghb", function()
  local default_branch = require("git").get_default_branch()
  require("gitsigns").change_base(default_branch, true)
end, { desc = "Change base to default branch" })

map("n", "<leader>ght", function()
  require("gitsigns").toggle_deleted()
  require("gitsigns").toggle_linehl()
  require("gitsigns").toggle_word_diff()
end, { desc = "Toggle inline diff" })

-- Blame
map("n", "<leader>gbb", function()
  require("gitsigns").blame()
end, { desc = "Blame on the side" })
