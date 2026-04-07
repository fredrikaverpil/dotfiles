-- File manager via oil.nvim.

vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/malewicz1337/oil-git.nvim" },
  { src = "https://github.com/JezerM/oil-lsp-diagnostics.nvim" },
})

require("oil").setup({
  keymaps = {
    ["<C-v>"] = { "actions.select", opts = { vertical = true } },
    ["<C-s>"] = { "actions.select", opts = { horizontal = true } },
    ["q"] = { "actions.close", mode = "n" },
  },
  view_options = { show_hidden = true },
  win_options = { signcolumn = "auto:2" },
})

require("oil-git").setup({ symbol_position = "signcolumn" })
require("oil-lsp-diagnostics").setup()

vim.keymap.set("n", "<C-->", "<cmd>Oil<cr>", { desc = "Oil" })
