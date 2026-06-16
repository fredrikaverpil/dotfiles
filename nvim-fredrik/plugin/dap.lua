require("lazyload").on_vim_enter(function()
  vim.pack.add({
    { src = "https://codeberg.org/mfussenegger/nvim-dap" },
    { src = "https://github.com/rcarriga/nvim-dap-ui" },
    { src = "https://github.com/nvim-neotest/nvim-nio", version = vim.version.range("*") },
    { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
    { src = "https://github.com/leoluz/nvim-dap-go" },
    { src = "https://codeberg.org/mfussenegger/nvim-dap-python" },
    { src = "https://github.com/jbyuki/one-small-step-for-vimkind" },
  })

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
  local osv = require("osv")

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

  -- lua (one-small-step-for-vimkind)
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

  -- go (nvim-dap-go)
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

  -- python (nvim-dap-python)
  require("dap-python").setup("uv")

  vim.keymap.set("n", "<leader>db", function()
    dap.toggle_breakpoint()
  end, { desc = "Toggle breakpoint" })
  vim.keymap.set("n", "<leader>dLl", function()
    osv.launch({ port = 8086 })
  end, { desc = "Debug Lua: launch server" })
  vim.keymap.set("n", "<leader>dLr", function()
    osv.run_this()
  end, { desc = "Debug Lua: run this" })
  vim.keymap.set("n", "<leader>dc", function()
    dap.continue()
  end, { desc = "Continue" })
  vim.keymap.set("n", "<leader>di", function()
    dap.step_into()
  end, { desc = "Step into" })
  vim.keymap.set("n", "<leader>do", function()
    dap.step_over()
  end, { desc = "Step over" })
  vim.keymap.set("n", "<leader>dO", function()
    dap.step_out()
  end, { desc = "Step out" })
  vim.keymap.set("n", "<leader>dq", function()
    dap.terminate()
  end, { desc = "Terminate" })
  vim.keymap.set("n", "<leader>du", function()
    dapui.toggle()
  end, { desc = "Toggle DAP UI" })
end)
