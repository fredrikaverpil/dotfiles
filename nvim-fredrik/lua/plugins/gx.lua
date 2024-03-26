return {

  {
    "chrishrb/gx.nvim",
    event = "VeryLazy",
    keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
    cmd = { "Browse" },
    -- init = function()
    --   vim.g.netrw_nogx = 1 -- disable netrw gx
    -- end,
    dependencies = { "nvim-lua/plenary.nvim" },
    config = true, -- default settings
  },
}
