if not Config.use_codediff then
  return
end

local github = require("github")

--- Base revision of the diff <leader>gdr opened, until its CodeDiffOpen.
--- @type string?
local pending_revision = nil

--- Continue the PR's draft review, or offer to start one.
--- @param pr_number string
local function start_or_continue_review(pr_number)
  github.fetch_reviews(pr_number, function()
    local head = vim.fn.trim(vim.fn.system("git rev-parse HEAD"))
    local pr_head = github.cache.head_oid
    if pr_head and head ~= pr_head then
      vim.notify(
        string.format("Local HEAD %s differs from PR #%s head %s", head:sub(1, 7), pr_number, pr_head:sub(1, 7)),
        vim.log.levels.WARN
      )
    end

    if github.cache.pending_review_node_id then
      vim.notify(string.format("Continuing draft review on PR #%s", pr_number), vim.log.levels.INFO)
      return
    end

    local prompt = string.format("No draft review on PR #%s. Start one?", pr_number)
    if vim.fn.confirm(prompt, "&Yes\n&No", 2) ~= 1 then
      return
    end
    github.ensure_pending_review(function()
      vim.notify(string.format("Draft review started on PR #%s", pr_number), vim.log.levels.INFO)
    end, function(msg)
      vim.notify(msg, vim.log.levels.ERROR)
    end)
  end, function(err)
    vim.notify("Failed to fetch PR reviews: " .. err, vim.log.levels.ERROR)
  end)
end

--- Take over the PR diff <leader>gdr opened once codediff has drawn it.
local function on_open(args)
  local data = args.data
  if not pending_revision or data.mode ~= "explorer" then
    return
  end
  local view = require("codediff.ui.lifecycle").get_panel_view(data.tabpage)
  if not (view and view.data and view.data.base_revision == pending_revision) then
    return
  end
  pending_revision = nil

  local pr_number = github.current_pr_number()
  if not pr_number then
    vim.notify("No pull request for the current branch", vim.log.levels.WARN)
    return
  end
  start_or_continue_review(pr_number)
end

require("lazyload").on_vim_enter(function()
  local group = vim.api.nvim_create_augroup("github_review", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = on_open,
  })

  vim.keymap.set("n", "<leader>gdr", function()
    pending_revision = require("git").get_pr_merge_base()
    vim.cmd(":CodeDiff " .. pending_revision)
  end, { desc = "Review current PR (GitHub-style)" })
end)
