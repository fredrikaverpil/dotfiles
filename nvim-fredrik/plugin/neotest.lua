require("lazyload").on_vim_enter(function()
  -- Adapters (and their plugin packs) are contributed per-language via
  -- require("lang").register({ neotest = { packs = ..., adapter = ... } }).
  local neotest_spec = require("lang").spec().neotest

  vim.pack.add(vim.list_extend({
    { src = "https://github.com/nvim-neotest/neotest", version = vim.version.range("*") },
    { src = "https://github.com/nvim-neotest/nvim-nio", version = vim.version.range("*") },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/antoinemadec/FixCursorHold.nvim" },
  }, neotest_spec.packs))

  local adapters = {}
  for _, build in ipairs(neotest_spec.adapters) do
    adapters[#adapters + 1] = build()
  end

  local neotest = require("neotest")

  ---@diagnostic disable-next-line: missing-fields
  neotest.setup({
    adapters = adapters,
    log_level = vim.log.levels.WARN,
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
  vim.keymap.set("n", "<leader>tf", function()
    neotest.run.run(vim.fn.expand("%"))
  end, { desc = "Run test file" })
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
