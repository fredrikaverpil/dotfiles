if not Config.use_codediff then
  return
end

local github = require("github")

--- PR review tabs opened by <leader>gdr. `files` is the set of PR paths, known
--- once their viewed states have loaded.
--- @type table<integer, { pr_number: string, files: table<string, boolean>? }>
local review_tabs = {}

--- Base revision of the diff <leader>gdr opened, until its CodeDiffOpen.
--- @type string?
local pending_revision = nil

--- Continue the PR's draft review, if any. The first comment starts one.
--- @param pr_number string
local function continue_review(pr_number)
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
    end
  end, function(err)
    vim.notify("Failed to fetch PR reviews: " .. err, vim.log.levels.ERROR)
  end)
end

--- Mark the tab's explorer rows for files already viewed on GitHub.
--- @param tabpage integer
--- @param pr_number string
local function load_viewed_files(tabpage, pr_number)
  github.fetch_viewed_files(pr_number, function(states)
    local tab = review_tabs[tabpage]
    if not tab then
      return
    end
    local codediff = require("codediff")
    local files = {}
    for path, state in pairs(states) do
      files[path] = true
      if state == "VIEWED" then
        codediff.set_reviewed(path, true, { tabpage = tabpage })
      end
    end
    tab.files = files
  end, function(err)
    vim.notify("Failed to fetch viewed files: " .. err, vim.log.levels.ERROR)
  end)
end

--- Mirror an explorer reviewed toggle into the file's viewed state on GitHub.
local function sync_viewed(args)
  local data = args.data
  local tab = review_tabs[data.tabpage]
  if not tab or data.mode ~= "explorer" then
    return
  end
  if not tab.files then
    vim.notify("Viewed files are still loading; mark not synced to GitHub", vim.log.levels.WARN)
    return
  end
  if not tab.files[data.path] then
    vim.notify(string.format("%s is not in PR #%s; mark kept local", data.path, tab.pr_number), vim.log.levels.INFO)
    return
  end

  github.set_file_viewed(data.path, data.reviewed, function() end, function(err)
    require("codediff").set_reviewed(data.path, not data.reviewed, { tabpage = data.tabpage })
    vim.notify(string.format("Failed to sync viewed state of %s: %s", data.path, err), vim.log.levels.ERROR)
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
  review_tabs[data.tabpage] = { pr_number = pr_number }
  load_viewed_files(data.tabpage, pr_number)
  continue_review(pr_number)
end

require("lazyload").on_vim_enter(function()
  local group = vim.api.nvim_create_augroup("github_review", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    callback = on_open,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffReviewedToggle",
    callback = sync_viewed,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffClose",
    callback = function(args)
      review_tabs[args.data.tabpage] = nil
    end,
  })

  vim.keymap.set("n", "<leader>gdr", function()
    pending_revision = require("git").get_pr_merge_base()
    vim.cmd(":CodeDiff " .. pending_revision)
  end, { desc = "Review current PR (GitHub-style)" })
end)
