M = {}

function M.is_code_private()
  local current_dir = vim.fn.getcwd()
  local home_dir = os.getenv("HOME") or os.getenv("USERPROFILE")
  local code_path = home_dir .. "/code"

  -- if git repo is filed under ~/code/work/private, assume code is private
  local private_path = code_path .. "/work/private"
  local private_path_detected = string.find(current_dir, private_path) == 1

  if private_path_detected then
    return true
  else
    return false
  end
end

function M.enable_ai()
  if require("utils.private").is_code_private() then
    return false
  end
  return true
end

function M.is_copilot_available()
  if require("utils.private").enable_ai() then
    if vim.fn.executable("node") == 1 then
      return true
    else
      vim.notify("Node is not available, but required for Copilot.", vim.log.levels.WARN)
      return false
    end
  end
  return false
end

function M.toggle_copilot()
  if require("utils.private").is_copilot_available() then
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

return M
