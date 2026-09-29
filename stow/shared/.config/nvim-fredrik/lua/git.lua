local M = {}

function M.get_default_branch()
  local result = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null")
  if vim.v.shell_error ~= 0 then
    return "main"
  end
  result = result:gsub("^refs/remotes/origin/", ""):gsub("%s+$", "")
  if result == "" then
    return "main"
  end
  return result
end

function M.get_pr_base_branch()
  local base = vim.fn.system("gh pr view --json baseRefName --jq .baseRefName 2>/dev/null")
  if vim.v.shell_error ~= 0 or base == "" then
    return M.get_default_branch()
  end
  return base:gsub("%s+$", "")
end

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
