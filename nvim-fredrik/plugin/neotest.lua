require("lazyload").on_vim_enter(function()
  local dev = require("dev")

  vim.pack.add({
    { src = "https://github.com/nvim-neotest/neotest" },
    { src = "https://github.com/nvim-neotest/nvim-nio" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/antoinemadec/FixCursorHold.nvim" },

    -- test adapters
    { src = "https://github.com/nvim-neotest/neotest-plenary" },
    { src = "https://github.com/nvim-neotest/neotest-python" },
    { src = "https://github.com/lawrence-laz/neotest-zig", version = vim.version.range("1.*") },

    -- neotest-golang
    { src = dev.prefer_local("~/code/public/neotest-golang", "https://github.com/fredrikaverpil/neotest-golang") },
    { src = "https://github.com/uga-rosa/utf8.nvim" },
  })

  local neotest = require("neotest")
  local neotest_defaults = require("neotest.config")

  local function clone(value)
    if type(value) == "table" then
      return vim.deepcopy(value)
    end
    return value
  end

  neotest.setup({
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

    -- NOTE: workaround for avoiding LSP warnings due to missing fields
    summary = vim.tbl_deep_extend("force", clone(neotest_defaults.summary), {
      animated = true,
    }),
    log_level = vim.log.levels.WARN,
    consumers = clone(neotest_defaults.consumers),
    icons = clone(neotest_defaults.icons),
    highlights = clone(neotest_defaults.highlights),
    floating = clone(neotest_defaults.floating),
    strategies = clone(neotest_defaults.strategies),
    run = clone(neotest_defaults.run),
    output = clone(neotest_defaults.output),
    output_panel = clone(neotest_defaults.output_panel),
    quickfix = clone(neotest_defaults.quickfix),
    status = clone(neotest_defaults.status),
    state = clone(neotest_defaults.state),
    watch = clone(neotest_defaults.watch),
    diagnostic = clone(neotest_defaults.diagnostic),
    projects = clone(neotest_defaults.projects),
    default_strategy = neotest_defaults.default_strategy,
  })

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("neotest-output", { clear = true }),
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
    neotest.run.run()
  end, { desc = "Run nearest test" })
  vim.keymap.set("n", "<leader>tT", function()
    neotest.run.run({ suite = true })
  end, { desc = "Run test suite" })
  vim.keymap.set("n", "<leader>tl", function()
    neotest.run.run_last()
  end, { desc = "Run last test" })
  vim.keymap.set("n", "<leader>ts", function()
    neotest.summary.toggle()
  end, { desc = "Toggle test summary" })
  vim.keymap.set("n", "<leader>to", function()
    neotest.output.open({ enter = true, auto_close = true })
  end, { desc = "Show test output" })
  vim.keymap.set("n", "<leader>tO", function()
    neotest.output_panel.toggle()
  end, { desc = "Toggle output panel" })
  vim.keymap.set("n", "<leader>tt", function()
    neotest.run.stop()
  end, { desc = "Terminate test" })
  vim.keymap.set("n", "<leader>td", function()
    neotest.summary.close()
    neotest.output_panel.close()
    neotest.run.run({ suite = false, strategy = "dap" })
  end, { desc = "Debug nearest test" })
end)
