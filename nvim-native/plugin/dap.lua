vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap", name = "nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  { src = "https://github.com/jbyuki/one-small-step-for-vimkind" }, -- Lua DAP adapter
  { src = "https://github.com/leoluz/nvim-dap-go" }, -- Go DAP adapter
})

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  require("nvim-dap-virtual-text").setup({ virt_text_pos = "eol" })

  local dap = require("dap")
  local dapui = require("dapui")

  dapui.setup()

  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end

  -- Lua DAP adapter (debug the running Neovim instance)
  dap.adapters.nlua = function(callback, config)
    callback({ type = "server", host = config.host or "127.0.0.1", port = config.port or 8086 })
  end
  dap.configurations.lua = {
    {
      type = "nlua",
      request = "attach",
      name = "Attach to running Neovim instance",
    },
  }

  -- Go DAP adapter (delve)
  require("dap-go").setup({
    dap_configurations = {
      {
        type = "go",
        name = "Delve: debug opened file's cmd/cli",
        request = "launch",
        cwd = "${fileDirname}",
        program = "./${relativeFileDirname}",
        args = {},
      },
      {
        type = "go",
        name = "Delve: debug test (manually enter test name)",
        request = "launch",
        mode = "test",
        program = "./${relativeFileDirname}",
        args = function()
          local testname = vim.fn.input("Test name (^regexp$ ok): ")
          return { "-test.run", testname }
        end,
      },
    },
  })
end

local map = function(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { desc = desc })
end

map("<leader>db", function()
  init()
  require("dap").toggle_breakpoint()
end, "Toggle breakpoint")
map("<leader>dLl", function()
  init()
  require("osv").launch({ port = 8086 })
end, "Debug Lua: launch server")
map("<leader>dLr", function()
  init()
  require("osv").run_this()
end, "Debug Lua: run this")
map("<leader>dc", function()
  init()
  require("dap").continue()
end, "Continue")
map("<leader>di", function()
  init()
  require("dap").step_into()
end, "Step into")
map("<leader>do", function()
  init()
  require("dap").step_over()
end, "Step over")
map("<leader>dO", function()
  init()
  require("dap").step_out()
end, "Step out")
map("<leader>dq", function()
  init()
  require("dap").terminate()
end, "Terminate")
map("<leader>du", function()
  init()
  require("dapui").toggle()
end, "Toggle DAP UI")
