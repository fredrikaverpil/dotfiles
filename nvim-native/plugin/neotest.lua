-- Neotest core
vim.pack.add({
  { src = "https://github.com/nvim-neotest/neotest" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/antoinemadec/FixCursorHold.nvim" },
})

-- Neotest adapters
vim.pack.add({
  { src = "https://github.com/nvim-neotest/neotest-plenary" },
  { src = "https://github.com/nvim-neotest/neotest-python" },
  { src = "https://github.com/lawrence-laz/neotest-zig", version = vim.version.range("1.*") },
})

-- neotest-golang
vim.pack.add({
  { src = "https://github.com/uga-rosa/utf8.nvim" },
})

require("dev").use({
  dev = "~/code/public/neotest-golang",
  fallback = function()
    vim.pack.add({
      { src = "https://github.com/fredrikaverpil/neotest-golang" },
    })
  end,
})

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  require("neotest").setup({
    adapters = {
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
      require("neotest-plenary"),
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

vim.keymap.set("n", "<leader>tn", function()
  init()
  require("neotest").run.run()
end, { desc = "Run nearest test" })
vim.keymap.set("n", "<leader>tT", function()
  init()
  require("neotest").run.run({ suite = true })
end, { desc = "Run test suite" })
vim.keymap.set("n", "<leader>tl", function()
  init()
  require("neotest").run.run_last()
end, { desc = "Run last test" })
vim.keymap.set("n", "<leader>ts", function()
  init()
  require("neotest").summary.toggle()
end, { desc = "Toggle test summary" })
vim.keymap.set("n", "<leader>to", function()
  init()
  require("neotest").output.open({ enter = true, auto_close = true })
end, { desc = "Show test output" })
vim.keymap.set("n", "<leader>tO", function()
  init()
  require("neotest").output_panel.toggle()
end, { desc = "Toggle output panel" })
vim.keymap.set("n", "<leader>tt", function()
  init()
  require("neotest").run.stop()
end, { desc = "Terminate test" })
vim.keymap.set("n", "<leader>td", function()
  init()
  require("neotest").summary.close()
  require("neotest").output_panel.close()
  require("neotest").run.run({ suite = false, strategy = "dap" })
end, { desc = "Debug nearest test" })
