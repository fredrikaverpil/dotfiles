M = {}

function is_code_private()
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
  if is_code_private() then
    return false
  end
  return true
end

return M
