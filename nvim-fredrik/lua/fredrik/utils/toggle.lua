M = {}

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

function M.toggle_quickfix_list(all_buffers)
  all_buffers = all_buffers or false

  local qf_open = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.fn.getwininfo(win)[1].quickfix == 1 then
      qf_open = true
      break
    end
  end

  if qf_open then
    vim.cmd("cclose")
  else
    -- Gather diagnostics based on all_buffers parameter
    local diagnostics
    if all_buffers then
      -- Get diagnostics from all buffers
      diagnostics = vim.diagnostic.toqflist(vim.diagnostic.get())
    else
      -- Get diagnostics from current buffer only
      local current_buf = vim.api.nvim_get_current_buf()
      diagnostics = vim.diagnostic.toqflist(vim.diagnostic.get(current_buf))
    end

    -- Set quickfix list with diagnostics
    vim.fn.setqflist(diagnostics, "r")
    vim.cmd("copen")

    -- Enable line wrapping in quickfix window
    vim.cmd("setlocal wrap")
  end
end

return M
