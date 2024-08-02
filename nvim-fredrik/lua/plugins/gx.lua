return {

  {
    "chrishrb/gx.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Browse" },
    -- init = function()
    --   vim.g.netrw_nogx = 1 -- disable netrw gx
    -- end,
    config = true, -- default settings
    keys = { { "gx", "<cmd>Browse<cr>", mode = { "n", "x" } } },
  },
}
