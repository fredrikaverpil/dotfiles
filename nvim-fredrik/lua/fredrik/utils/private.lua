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

local function is_copilot_available()
  if is_code_public() then
    if vim.fn.executable("node") == 1 then
      return true
    else
      vim.notify("Node is not available, but required for Copilot.", vim.log.levels.WARN)
      return false
    end
  end
  return false
end

-- export functions for use by e.g. plugins
M.is_code_public = is_code_public
M.is_copilot_available = is_copilot_available

return M
