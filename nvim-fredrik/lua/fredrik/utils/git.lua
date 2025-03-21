M = {}

-- Function to detect the default branch name
function M.get_default_branch()
  -- Execute git symbolic-ref command

  local result = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null")

  -- Check for errors
  if vim.v.shell_error ~= 0 then
    return "main" -- fallback to main if command fails
  end

  -- Extract just the branch name from the full reference path
  result = result:gsub("^refs/remotes/origin/", ""):gsub("%s+$", "")

  if result ~= "master" and result ~= "main" then
    vim.notify("Default branch detected as: " .. result, vim.log.levels.WARN)
  end

  if result == "" then
    return "main" -- fallback to main if empty result
  end

  return result
end

return M
