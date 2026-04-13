require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://github.com/lewis6991/gitsigns.nvim" }, -- calls setup() internally
  })

  -- Hunk navigation
  vim.keymap.set("n", "]h", function()
    if vim.wo.diff then
      return "]c"
    end
    vim.schedule(function()
      require("gitsigns").nav_hunk("next")
    end)
    return "<Ignore>"
  end, { expr = true, desc = "Next hunk" })

  vim.keymap.set("n", "[h", function()
    if vim.wo.diff then
      return "[c"
    end
    vim.schedule(function()
      require("gitsigns").nav_hunk("prev")
    end)
    return "<Ignore>"
  end, { expr = true, desc = "Prev hunk" })

  -- Hunk actions
  vim.keymap.set({ "n", "v" }, "<leader>ghs", function()
    require("gitsigns").stage_hunk()
  end, { desc = "Stage hunk" })

  vim.keymap.set({ "n", "v" }, "<leader>ghS", function()
    require("gitsigns").stage_buffer()
  end, { desc = "Stage buffer" })

  vim.keymap.set("n", "<leader>ghr", function()
    require("gitsigns").reset_hunk()
  end, { desc = "Reset hunk" })

  vim.keymap.set({ "n", "v" }, "<leader>ghb", function()
    local default_branch = require("git").get_default_branch()
    require("gitsigns").change_base(default_branch, true)
  end, { desc = "Change base to default branch" })

  vim.keymap.set("n", "<leader>ght", function()
    require("gitsigns").toggle_deleted()
    require("gitsigns").toggle_linehl()
    require("gitsigns").toggle_word_diff()
  end, { desc = "Toggle inline diff" })

  -- Blame
  vim.keymap.set("n", "<leader>gbb", function()
    require("gitsigns").blame()
  end, { desc = "Blame on the side" })
end)
