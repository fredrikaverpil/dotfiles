vim.pack.add({
  { src = "https://github.com/nvim-neotest/neotest" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/antoinemadec/FixCursorHold.nvim" },
  { src = "https://github.com/nvim-neotest/neotest-plenary" },
  { src = "https://github.com/uga-rosa/utf8.nvim" },
  { src = "https://github.com/nvim-neotest/neotest-python" },
  { src = "https://github.com/lawrence-laz/neotest-zig", version = vim.version.range("1.*") },
})

-- neotest-golang: prefer local dev clone, fall back to GitHub.
local neotest_golang_dev = vim.fn.expand("~/code/public/neotest-golang")
if vim.uv.fs_stat(neotest_golang_dev) then
  vim.opt.runtimepath:append(neotest_golang_dev)
else
  vim.pack.add({
    { src = "https://github.com/fredrikaverpil/neotest-golang" },
  })
end

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  require("neotest").setup({
    adapters = {
      require("neotest-plenary"),
      require("neotest-golang")({
        go_test_args = {
          "-v",
          "-count=1",
          "-race",
          "-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out",
          "-parallel=1",
        },
        runner = "gotestsum",
        gotestsum_args = { "--format=standard-verbose" },
      }),
      require("neotest-python")({
        runner = "pytest",
        args = { "--log-level", "INFO", "--color", "yes", "-vv", "-s" },
        dap = { justMyCode = false },
      }),
      require("neotest-zig")({
        dap = { adapter = "lldb" },
      }),
    },
    discovery = {
      enabled = true,
      concurrent = 0,
    },
    running = { concurrent = true },
    summary = { animated = true },
    log_level = vim.log.levels.WARN,
  })
end

-- Open file under cursor in the widest window when in neotest-output.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "neotest-output",
  callback = function()
    vim.keymap.set("n", "gF", function()
      local current_word = vim.fn.expand("<cWORD>")
      local tokens = vim.split(current_word, ":", { trimempty = true })
      local widest_win_id, widest_win_width = -1, -1
      for _, win_id in ipairs(vim.api.nvim_list_wins()) do
        if not vim.api.nvim_win_get_config(win_id).zindex then
          local w = vim.api.nvim_win_get_width(win_id)
          if w > widest_win_width then
            widest_win_width = w
            widest_win_id = win_id
          end
        end
      end
      vim.api.nvim_set_current_win(widest_win_id)
      if #tokens == 1 then
        vim.cmd("e " .. tokens[1])
      else
        vim.cmd("e +" .. tokens[2] .. " " .. tokens[1])
      end
    end, { remap = true, buffer = true })
  end,
})

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("<leader>tt", function()
  init()
  require("neotest").run.run()
end, "Run nearest test")
map("<leader>tT", function()
  init()
  require("neotest").run.run(vim.fn.expand("%"))
end, "Run file tests")
map("<leader>ts", function()
  init()
  require("neotest").summary.toggle()
end, "Toggle test summary")
map("<leader>to", function()
  init()
  require("neotest").output.open({ enter = true })
end, "Open test output")
map("<leader>tl", function()
  init()
  require("neotest").run.run_last()
end, "Run last test")
