-- Custom snacks pickers.

local M = {}

---@param picker snacks.Picker
---@param cmd_name? string
local function run_picker_system(picker, cmd_name)
  local ns = vim.api.nvim_create_namespace("run_picker_system")
  return function(cmd, opts, on_exit)
    on_exit = on_exit or function() end
    local timer = assert(vim.uv.new_timer())
    local cmd_text = cmd_name or table.concat(cmd, " ")
    local extmark_id = 999
    timer:start(
      0,
      80,
      vim.schedule_wrap(function()
        vim.api.nvim_buf_set_extmark(picker.input.win.buf, ns, 0, 0, {
          id = extmark_id,
          virt_text = {
            { cmd_text, "SnacksPickerDimmed" },
            { " " },
            { Snacks.util.spinner() .. " ", "SnacksPickerSpinner" },
          },
          virt_text_pos = "right_align",
        })
      end)
    )
    return vim.system(cmd, opts, function(out)
      timer:stop()
      timer:close()
      vim.schedule(function()
        vim.api.nvim_buf_del_extmark(picker.input.win.buf, ns, extmark_id)
        on_exit(out)
      end)
    end)
  end
end

---@param opts? snacks.picker.Config
function M.pull_requests(opts)
  local pr_cache = {} ---@type table<string, snacks.picker.finder.Item[]>

  return Snacks.picker.pick(vim.tbl_deep_extend("keep", opts or {}, {
    title = "Pull Requests",
    pr_filter = "open",
    actions = {
      filter_draft = function(picker)
        picker.opts.pr_filter = picker.opts.pr_filter == "draft" and "open" or "draft"
        picker.list:set_target()
        picker:find()
      end,
      filter_closed = function(picker)
        picker.opts.pr_filter = picker.opts.pr_filter == "closed" and "open" or "closed"
        picker.list:set_target()
        picker:find()
      end,
      filter_merged = function(picker)
        picker.opts.pr_filter = picker.opts.pr_filter == "merged" and "open" or "merged"
        picker.list:set_target()
        picker:find()
      end,
    },
    win = {
      input = {
        keys = {
          ["<a-d>"] = { "filter_draft", mode = { "i", "n" } },
          ["<a-c>"] = { "filter_closed", mode = { "i", "n" } },
          ["<a-m>"] = { "filter_merged", mode = { "i", "n" } },
        },
      },
    },
    finder = function(_f_opts, ctx)
      local filter = ctx.picker.opts.pr_filter
      local gh_state = (filter == "draft" or filter == "open") and "open" or filter
      local cache_key = gh_state

      if not pr_cache[cache_key] then
        local result = vim
          .system(
            { "gh", "pr", "list", "--state", gh_state, "--limit", "200", "--json", "number,title,body,isDraft,state" },
            { text = true }
          )
          :wait()
        if result.code ~= 0 then
          vim.notify("gh pr list failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
          return {}
        end
        local ok, prs = pcall(vim.json.decode, result.stdout)
        if not ok or not prs then
          return {}
        end
        pr_cache[cache_key] = {}
        for _, pr in ipairs(prs) do
          table.insert(pr_cache[cache_key], {
            text = "#" .. pr.number .. " " .. pr.title,
            pr_number = tostring(pr.number),
            pr_title = pr.title,
            pr_body = pr.body or "",
            pr_draft = pr.isDraft,
            pr_state = pr.state,
          })
        end
      end

      local items = {}
      for _, item in ipairs(pr_cache[cache_key]) do
        local include = (filter == "open" and not item.pr_draft)
          or (filter == "draft" and item.pr_draft)
          or (filter == "closed")
          or (filter == "merged")
        if include then
          table.insert(items, item)
        end
      end
      return items
    end,
    confirm = function(picker, item)
      run_picker_system(picker)({ "gh", "pr", "checkout", item.pr_number }, { timeout = 10000 }, function(out)
        picker:close()
        vim.schedule(function()
          Snacks.notify.info(out.stderr)
        end)
      end)
    end,
    format = function(item)
      local res = {}
      table.insert(res, { "#" .. item.pr_number, "Function" })
      table.insert(res, { " " })
      if item.pr_state == "CLOSED" then
        table.insert(res, { "[closed] ", "SnacksPickerDimmed" })
      elseif item.pr_state == "MERGED" then
        table.insert(res, { "[merged] ", "SnacksPickerDimmed" })
      elseif item.pr_draft then
        table.insert(res, { "[draft] ", "SnacksPickerDimmed" })
      end
      table.insert(res, { item.pr_title })
      return res
    end,
    preview = function(ctx)
      ctx.preview:highlight({ ft = "markdown" })
      ctx.preview:set_lines(vim.split(ctx.item.pr_body, [[\r\n]]))
    end,
  } --[[@as snacks.picker.Config]]))
end

---@param opts? snacks.picker.Config
function M.neovim_logs(opts)
  local log_dir = vim.fn.stdpath("log")
  if vim.fn.isdirectory(log_dir) == 0 then
    vim.notify("Neovim log directory not found at: " .. log_dir, vim.log.levels.WARN)
    return
  end

  return Snacks.picker.files(vim.tbl_deep_extend("keep", opts or {}, {
    title = "Neovim Log Files",
    cwd = log_dir,
    confirm = function(picker, item)
      local selected = picker:selected({ fallback = true })
      picker:close()
      for i, selected_item in ipairs(selected) do
        local full_path = picker:cwd() .. "/" .. selected_item.file
        if i == 1 then
          vim.cmd("split " .. vim.fn.fnameescape(full_path))
        else
          vim.cmd("vsplit " .. vim.fn.fnameescape(full_path))
        end
        vim.cmd("set ft=log")
        vim.cmd("normal! G")
      end
    end,
  }))
end

---@class GoPackageSymbolsOpts: snacks.picker.Config
---@field file_types? string[]

---@param opts? GoPackageSymbolsOpts
function M.go_package_symbols(opts)
  opts = opts or {}
  local file_types = opts.file_types
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.fnamemodify(current_file, ":h")

  local function get_package_files(ft)
    ft = ft or { "GoFiles", "CgoFiles", "TestGoFiles", "XTestGoFiles" }
    local result = vim.system({ "go", "list", "-json", "-find", "." }, { cwd = current_dir, text = true }):wait()
    if result.code ~= 0 then
      vim.notify("Failed to get Go package info: " .. (result.stderr or ""), vim.log.levels.WARN)
      return nil
    end
    local ok, pkg_info = pcall(vim.json.decode, result.stdout)
    if not ok then
      vim.notify("Failed to parse go list output", vim.log.levels.WARN)
      return nil
    end
    local files = {}
    local pkg_dir = pkg_info.Dir or current_dir
    for _, file_type in ipairs(ft) do
      for _, file in ipairs(pkg_info[file_type] or {}) do
        table.insert(files, pkg_dir .. "/" .. file)
      end
    end
    return files
  end

  local function get_lsp_symbols_and_client(file_path)
    local bufnr = vim.fn.bufadd(file_path)
    vim.fn.bufload(bufnr)
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if vim.tbl_isempty(clients) then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("doautocmd BufReadPost")
      end)
      vim.wait(100, function()
        clients = vim.lsp.get_clients({ bufnr = bufnr })
        return not vim.tbl_isempty(clients)
      end)
    end
    local params = { textDocument = { uri = vim.uri_from_bufnr(bufnr) } }
    local results = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 2000)
    if not results or vim.tbl_isempty(results) then
      return nil, nil
    end
    for client_id, result in pairs(results) do
      if result.result then
        return result.result, vim.lsp.get_client_by_id(client_id)
      end
    end
    return nil, nil
  end

  local title = "Go Package Symbols"
  if file_types then
    local has_tests = vim.tbl_contains(file_types, "TestGoFiles") or vim.tbl_contains(file_types, "XTestGoFiles")
    local has_regular = vim.tbl_contains(file_types, "GoFiles") or vim.tbl_contains(file_types, "CgoFiles")
    if has_tests and not has_regular then
      title = "Go Package Test Symbols"
    elseif has_tests and has_regular then
      title = "Go Package Symbols (All)"
    end
  end

  return Snacks.picker.pick(vim.tbl_deep_extend("keep", opts or {}, {
    title = title,
    tree = true,
    filter = {
      default = {
        "Class",
        "Constructor",
        "Enum",
        "Field",
        "Function",
        "Interface",
        "Method",
        "Module",
        "Namespace",
        "Package",
        "Property",
        "Struct",
        "Trait",
      },
    },
    finder = function(_f_opts, ctx)
      if ctx.picker.matcher then
        ctx.picker.matcher.opts.keep_parents = true
        ctx.picker.matcher.opts.sort = false
      end
      local package_files = get_package_files(file_types)
      if not package_files or #package_files == 0 then
        vim.notify("No Go package files found, falling back to current file symbols", vim.log.levels.INFO)
        vim.schedule(function()
          Snacks.picker.lsp_symbols()
        end)
        return {}
      end

      local lsp_source = require("snacks.picker.source.lsp")
      local picker_opts = ctx.picker.opts
      local filter = picker_opts.filter[vim.bo.filetype]
      if filter == nil then
        ---@diagnostic disable-next-line: undefined-field
        filter = picker_opts.filter.default
      end

      local function want(kind)
        kind = kind or "Unknown"
        return type(filter) == "boolean" or vim.tbl_contains(filter, kind)
      end

      local all_items = {}
      local shared_root = { text = "", root = true }

      for _, file_path in ipairs(package_files) do
        local lsp_symbols, client = get_lsp_symbols_and_client(file_path)
        if lsp_symbols and client then
          local items = lsp_source.results_to_items(client, lsp_symbols, {
            default_uri = vim.uri_from_fname(file_path),
            filter = function(result)
              return want(lsp_source.symbol_kind(result.kind))
            end,
          })
          for _, item in ipairs(items) do
            item.tree = true
            if item.parent and item.parent.root then
              item.parent = shared_root
            end
          end
          vim.list_extend(all_items, items)
        end
      end

      local last = {} ---@type table<snacks.picker.finder.Item, snacks.picker.finder.Item>
      for _, item in ipairs(all_items) do
        item.last = nil
        local parent = item.parent
        if parent then
          if last[parent] then
            last[parent].last = nil
          end
          last[parent] = item
          item.last = true
        end
      end

      return all_items
    end,
    format = "lsp_symbol",
    confirm = function(picker, item)
      picker:close()
      vim.cmd("edit " .. vim.fn.fnameescape(item.file))
      if item.pos then
        vim.api.nvim_win_set_cursor(0, item.pos)
      end
    end,
  }))
end

return M
