local registry = require("registry")

vim.pack.add({
  { src = "https://github.com/nvim-neotest/neotest" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/antoinemadec/FixCursorHold.nvim" },
})

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  local adapters = {}
  for _, spec in ipairs(registry.neotest.adapters) do
    local adapter = require(spec.module)
    if spec.opts then
      adapter = adapter(spec.opts)
    end
    table.insert(adapters, adapter)
  end

  require("neotest").setup({
    adapters = adapters,
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

map("<leader>tn", function()
  init()
  require("neotest").run.run()
end, "Run nearest test")
map("<leader>tT", function()
  init()
  require("neotest").run.run({ suite = true })
end, "Run test suite")
map("<leader>tl", function()
  init()
  require("neotest").run.run_last()
end, "Run last test")
map("<leader>ts", function()
  init()
  require("neotest").summary.toggle()
end, "Toggle test summary")
map("<leader>to", function()
  init()
  require("neotest").output.open({ enter = true, auto_close = true })
end, "Show test output")
map("<leader>tO", function()
  init()
  require("neotest").output_panel.toggle()
end, "Toggle output panel")
map("<leader>tt", function()
  init()
  require("neotest").run.stop()
end, "Terminate test")
map("<leader>td", function()
  init()
  require("neotest").summary.close()
  require("neotest").output_panel.close()
  require("neotest").run.run({ suite = false, strategy = "dap" })
end, "Debug nearest test")
