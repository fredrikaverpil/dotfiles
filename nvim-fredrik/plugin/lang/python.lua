-- Resolved at use time so :cd after startup still finds the profile
-- written by neotest (plugin/neotest.lua uses the same path).
local function coverage_file()
  return vim.fs.joinpath(vim.fn.getcwd(), "coverage.out")
end

require("lang").register("python", {
  servers = { "basedpyright", "ruff" },
  mason = { "basedpyright", "ruff", "mypy", "debugpy" },
  linters_by_ft = { python = { "mypy" } },
  coverage = { python = { coverage_file = coverage_file } },
  neotest = {
    packs = {
      { src = "https://github.com/nvim-neotest/neotest-python" },
    },
    adapter = function()
      return require("neotest-python")({
        runner = "pytest",
        args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
        dap = { justMyCode = false },
      })
    end,
  },
  dap = {
    packs = {
      { src = "https://codeberg.org/mfussenegger/nvim-dap-python" },
    },
    setup = function()
      require("dap-python").setup("uv")
    end,
  },
})

require("lazyload").on_vim_enter(function()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("python-opts", { clear = true }),
    pattern = "python",
    callback = function()
      vim.opt_local.tabstop = 4
      vim.opt_local.softtabstop = 4
      vim.opt_local.shiftwidth = 4
    end,
  })
end)
