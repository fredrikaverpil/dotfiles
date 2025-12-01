local M = {}

local orig_fmt_func = vim.lsp.handlers["textDocument/formatting"]
local foldmethod = nil

function M.toggle_formatting()
  vim.g.auto_format = not vim.g.auto_format -- reverse the value

  if vim.g.auto_format then
    vim.lsp.handlers["textDocument/formatting"] = orig_fmt_func
  else
    vim.lsp.handlers["textDocument/formatting"] = function() end
  end

  if vim.g.auto_format then
    vim.notify("Auto-formatting enabled", vim.log.levels.INFO)
  else
    vim.notify("Auto-formatting disabled", vim.log.levels.INFO)
  end
end

function M.toggle_inlay_hints()
  local filter = {}
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter))
end

function M.toggle_manual_folding()
  if foldmethod == "manual" then
    vim.wo.foldmethod = "expr"
    foldmethod = nil
    vim.notify("Foldmethod set to expr", vim.log.levels.INFO)
  else
    vim.wo.foldmethod = "manual"
    foldmethod = vim.wo.foldmethod
    vim.notify("Foldmethod set to manual", vim.log.levels.INFO)
  end
end

function M.toggle_copilot(opts)
  opts = opts or {}

  if not package.loaded["copilot"] then
    vim.notify("Copilot is not loaded", vim.log.levels.WARN)
    return
  end

  local private_utils = require("fredrik.utils.private")
  local is_available = private_utils.is_copilot_available()
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
  local is_enabled = vim.g.custom_copilot_status == "enabled"

  -- Determine target state: toggle if called manually, else sync to availability
  local should_enable = opts.manual and not is_enabled or (not opts.manual and is_available)

  if should_enable and not is_available then
    vim.notify(string.format("Cannot enable Copilot: Not in public directory\n%s", cwd), vim.log.levels.ERROR)
    return
  end

  vim.cmd(should_enable and "Copilot enable" or "Copilot disable")
  vim.lsp.enable("copilot", should_enable)
  vim.g.custom_copilot_status = should_enable and "enabled" or "disabled"

  vim.schedule(function()
    vim.notify(
      string.format("[Copilot] %s: %s", vim.g.custom_copilot_status, cwd),
      should_enable and vim.log.levels.INFO or vim.log.levels.WARN
    )
  end)
end

return M
