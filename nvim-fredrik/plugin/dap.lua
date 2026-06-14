require("lazyload").on_vim_enter(function()
  -- Adapters/configs (and their plugin packs) are contributed per-language via
  -- require("lang").register({ dap = { packs = ..., setup = ... } }).
  local dap_spec = require("lang").spec().dap

  vim.pack.add(vim.list_extend({
    { src = "https://codeberg.org/mfussenegger/nvim-dap" },
    { src = "https://github.com/rcarriga/nvim-dap-ui" },
    { src = "https://github.com/nvim-neotest/nvim-nio", version = vim.version.range("*") },
    { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  }, dap_spec.packs))

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

  -- Per-language adapters and configurations.
  for _, setup in ipairs(dap_spec.setups) do
    setup(dap)
  end

  vim.keymap.set("n", "<leader>db", function()
    dap.toggle_breakpoint()
  end, { desc = "Toggle breakpoint" })
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
