return {
  -- Modify which-key keys
  {
    "folke/which-key.nvim",
    opts = function()
      require("which-key").register({
        ["<leader>t"] = {
          name = "+test",
        },
        ["<leader>gb"] = {
          name = "+blame",
        },
        ["<leader>gd"] = {
          name = "+diffview",
        },
        ["<leader>h"] = {
          name = "+harpoon",
        },
        ["<leader>r"] = {
          name = "+run",
        },
      })
    end,
  },
}
