vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap", name = "nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
})

local registry = require("registry")

registry.add({
  lualine = {
    lualine_x = {
      {
        function()
          return require("dap").status()
        end,
        cond = function()
          return package.loaded["dap"] and require("dap").status() ~= ""
        end,
        icon = "",
      },
    },
  },
})

local initialized = false

local function init()
  if initialized then
    return
  end
  initialized = true

  -- Show nice icons in gutter instead of the default characters
  for name, sign in pairs(require("icons").dap) do
    sign = type(sign) == "table" and sign or { sign }
    vim.fn.sign_define("Dap" .. name, {
      text = sign[1],
      texthl = sign[2] or "DiagnosticInfo",
      linehl = sign[3],
      numhl = sign[3],
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

  -- Apply registry adapters and configurations
  local merge = require("merge")
  merge(dap.adapters, registry.dap.adapters or {})
  merge(dap.configurations, registry.dap.configurations or {})

  -- Run lang-specific setup functions (e.g. dap-go, dap-python)
  for _, setup_fn in ipairs(registry.dap.setups or {}) do
    setup_fn()
  end
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
