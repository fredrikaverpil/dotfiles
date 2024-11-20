M = {}

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

local function is_ai_enabled()
  if is_code_public() then
    return true
  end
  return false
end

local function is_copilot_available()
  if is_ai_enabled() then
    if vim.fn.executable("node") == 1 then
      return true
    else
      vim.notify("Node is not available, but required for Copilot.", vim.log.levels.WARN)
      return false
    end
  end
  return false
end

local function toggle_copilot()
  if is_copilot_available() then
    local output = vim.fn.execute("Copilot status")
    if string.match(output, "Not Started") or string.match(output, "Offline") then
      -- avoid starting multiple servers
      vim.cmd("Copilot enable")
      vim.g.custom_copilot_status = "enabled"
    end
  else
    vim.cmd("Copilot disable")
    vim.g.custom_copilot_status = "disabled"
  end
end

-- export functions for use by e.g. plugins
M.is_code_public = is_code_public
M.is_ai_enabled = is_ai_enabled
M.is_copilot_availble = is_copilot_available
M.toggle_copilot = toggle_copilot

return M
