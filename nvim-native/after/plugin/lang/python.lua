-- Python: linters, DAP.

require("lint").linters_by_ft.python = { "mypy" }

-- DAP: debugpy via dap-python
vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap-python", name = "nvim-dap-python" },
})

require("dap-python").setup("uv")
