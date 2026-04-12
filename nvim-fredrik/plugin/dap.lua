-- DAP packages — registered on disk now, but not added to packpath until
-- first keymap press. This avoids sourcing the plugins' plugin/ files for
-- sessions where you never debug.
local packages = {
  -- Core
  { src = "https://codeberg.org/mfussenegger/nvim-dap", name = "nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui", name = "nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio", name = "nvim-nio" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text", name = "nvim-dap-virtual-text" },
  -- Adapters
  { src = "https://github.com/leoluz/nvim-dap-go", name = "nvim-dap-go" },
  { src = "https://codeberg.org/mfussenegger/nvim-dap-python", name = "nvim-dap-python" },
}
vim.pack.add(packages, { load = function() end })

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  for _, p in ipairs(packages) do
    vim.cmd.packadd(p.name)
  end

  -- Show nice icons in gutter instead of the default characters
  for name, sign in pairs(require("icons").dap) do
    ---@type string[]
    local parts = type(sign) == "table" and sign or { sign }
    vim.fn.sign_define("Dap" .. name, {
      text = parts[1],
      texthl = parts[2] or "DiagnosticInfo",
      linehl = parts[3],
      numhl = parts[3],
    })
  end

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

  -- Lua DAP adapter
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

  -- Go DAP setup
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

  -- Python DAP setup
  require("dap-python").setup("uv")
end

vim.keymap.set("n", "<leader>db", function()
  init()
  require("dap").toggle_breakpoint()
end, { desc = "Toggle breakpoint" })
vim.keymap.set("n", "<leader>dLl", function()
  init()
  require("osv").launch({ port = 8086 })
end, { desc = "Debug Lua: launch server" })
vim.keymap.set("n", "<leader>dLr", function()
  init()
  require("osv").run_this()
end, { desc = "Debug Lua: run this" })
vim.keymap.set("n", "<leader>dc", function()
  init()
  require("dap").continue()
end, { desc = "Continue" })
vim.keymap.set("n", "<leader>di", function()
  init()
  require("dap").step_into()
end, { desc = "Step into" })
vim.keymap.set("n", "<leader>do", function()
  init()
  require("dap").step_over()
end, { desc = "Step over" })
vim.keymap.set("n", "<leader>dO", function()
  init()
  require("dap").step_out()
end, { desc = "Step out" })
vim.keymap.set("n", "<leader>dq", function()
  init()
  require("dap").terminate()
end, { desc = "Terminate" })
vim.keymap.set("n", "<leader>du", function()
  init()
  require("dapui").toggle()
end, { desc = "Toggle DAP UI" })
