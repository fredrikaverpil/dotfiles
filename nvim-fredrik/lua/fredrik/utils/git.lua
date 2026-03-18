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

--- Get the base branch for the current PR via `gh`, or fall back to default branch.
function M.get_pr_base_branch()
  local base = vim.fn.system("gh pr view --json baseRefName --jq .baseRefName 2>/dev/null")
  if vim.v.shell_error ~= 0 or base == "" then
    return M.get_default_branch()
  end
  return base:gsub("%s+$", "")
end

--- Get the merge-base commit between origin/<base> and HEAD (GitHub-style diff base).
--- Fetches the remote base branch first to ensure up-to-date refs.
function M.get_pr_merge_base()
  local base = M.get_pr_base_branch()
  vim.fn.system("git fetch origin " .. base .. " 2>/dev/null")
  local merge_base = vim.fn.system("git merge-base origin/" .. base .. " HEAD 2>/dev/null")
  if vim.v.shell_error ~= 0 or merge_base == "" then
    return "origin/" .. base
  end
  return merge_base:gsub("%s+$", "")
end

return M
