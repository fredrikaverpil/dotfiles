local M = {}

local function is_code_public()
  local public_paths = {
    "~/.dotfiles",
    "~/code/public/",
    "~/code/work/public",
  }

  for _, public_path in ipairs(public_paths) do
    local public_path_detected = string.find(vim.fn.getcwd(), vim.fn.expand(public_path)) == 1
    if public_path_detected then
      return true
    end
  end
  return false
end

local function is_node_available()
  if not vim.fn.executable("node") == 1 then
    vim.notify("Node is not available, but required for Copilot.", vim.log.levels.WARN)
    return false
  end
  return true
end

local function is_copilot_lsp_available()
  if not vim.fn.executable("copilot-language-server") == 1 then
    vim.notify("copilot-language-server is not available, but required for Copilot.", vim.log.levels.WARN)
    return false
  end
  return true
end

local function is_copilot_available()
  if not is_code_public() then
    return false
  end
  if not is_node_available() then
    return false
  end
  if not is_copilot_lsp_available() then
    return false
  end
  return true
end

local function is_copilot_loaded()
  if not package.loaded["copilot"] then
    -- vim.notify("Copilot is not loaded", vim.log.levels.WARN)
    return false
  end

  local ok, _ = pcall(require, "copilot")
  if not ok then
    vim.notify(vim.inspect("The Copilot plugin is not loaded"), vim.log.levels.WARN)
    return false
  end
  return true
end

-- export functions for use by e.g. plugins
M.is_code_public = is_code_public
M.is_copilot_lsp_available = is_copilot_lsp_available
M.is_copilot_available = is_copilot_available
M.is_copilot_loaded = is_copilot_loaded

return M
