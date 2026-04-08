require("lint").linters_by_ft.python = { "mypy" }

-- DAP: debugpy via dap-python
vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap-python", name = "nvim-dap-python" },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  once = true,
  callback = function()
    require("dap-python").setup("uv")
  end,
})
