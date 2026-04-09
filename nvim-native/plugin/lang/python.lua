vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap-python", name = "nvim-dap-python" },
  { src = "https://github.com/nvim-neotest/neotest-python" },
})

require("registry").add({
  lsp_servers = { "basedpyright", "ruff" },
  mason_ensure_installed = { "basedpyright", "ruff", "mypy", "debugpy" },
  lint = {
    linters_by_ft = { python = { "mypy" } },
  },
  neotest = {
    adapters = {
      {
        module = "neotest-python",
        opts = {
          runner = "pytest",
          args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
          dap = { justMyCode = false },
        },
      },
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  once = true,
  callback = function()
    require("dap-python").setup("uv")
  end,
})
