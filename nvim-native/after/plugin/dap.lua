local registry = require("registry")

vim.pack.add({
  { src = "https://codeberg.org/mfussenegger/nvim-dap", name = "nvim-dap" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
})

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
  for name, adapter in pairs(registry.dap.adapters) do
    dap.adapters[name] = adapter
  end
  for ft, configs in pairs(registry.dap.configurations) do
    dap.configurations[ft] = configs
  end

  -- Run lang-specific setup functions (e.g. dap-go, dap-python)
  for _, setup_fn in ipairs(registry.dap.setups) do
    setup_fn()
  end
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
