local M = {}

---@param picker snacks.Picker
---@param cmd_name? string
local function run_picker_system(picker, cmd_name)
  local ns = vim.api.nvim_create_namespace("run_picker_system")
  ---@param cmd string[]
  ---@param opts? vim.SystemOpts
  ---@param on_exit? fun(out: vim.SystemCompleted)
  ---@return vim.SystemObj
  return function(cmd, opts, on_exit)
    on_exit = on_exit or function() end
    local timer = assert(vim.uv.new_timer())
    local cmd_text = cmd_name or table.concat(cmd, " ")
    local extmark_id = 999
    timer:start(
      0,
      80,
      vim.schedule_wrap(function()
        local virtual_text = {}
        table.insert(virtual_text, { cmd_text, "SnacksPickerDimmed" })
        table.insert(virtual_text, { " " })
        table.insert(virtual_text, { Snacks.util.spinner() .. " ", "SnacksPickerSpinner" })
        vim.api.nvim_buf_set_extmark(picker.input.win.buf, ns, 0, 0, {
          id = extmark_id,
          virt_text = virtual_text,
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
  return Snacks.picker.pick(vim.tbl_deep_extend("keep", opts or {}, {
    title = "Pull Requests",
    finder = function(f_opts, ctx)
      return require("snacks.picker.source.proc").proc(
        vim.tbl_deep_extend("force", f_opts or {}, {
          cmd = "gh",
          args = { "pr", "list", "--json", "number,title,body", "--jq", ".[] | [.number, .title, .body] | @tsv" },
          transform = function(item) ---@param item snacks.picker.finder.Item
            local split = vim.split(item.text, "\t")
            item.pr_number = tonumber(split[1])
            item.pr_title = split[2]
            item.pr_body = split[3]
          end,
        }),
        ctx
      )
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

  -- Check if log directory exists
  if vim.fn.isdirectory(log_dir) == 0 then
    vim.notify("Neovim log directory not found at: " .. log_dir, vim.log.levels.WARN)
    return
  end

  -- Open picker for log files
  return Snacks.picker.files(vim.tbl_deep_extend("keep", opts or {}, {
    title = "Neovim Log Files",
    cwd = log_dir,
    confirm = function(picker, item)
      local selected = picker:selected({ fallback = true })
      picker:close()

      for i, selected_item in ipairs(selected) do
        local full_path = picker:cwd() .. "/" .. selected_item.file
        if i == 1 then
          -- First file: open in horizontal split
          vim.cmd("split " .. vim.fn.fnameescape(full_path))
        else
          -- Additional files: open in vertical splits
          vim.cmd("vsplit " .. vim.fn.fnameescape(full_path))
        end
        vim.cmd("set ft=log")
        vim.cmd("normal! G")
      end
    end,
  }))
end

---@param opts? snacks.picker.Config
function M.go_package_symbols(opts)
  -- Get the current file's directory
  local current_file = vim.fn.expand("%:p")
  local current_dir = vim.fn.fnamemodify(current_file, ":h")

  -- Helper function to get Go package files
  local function get_package_files()
    local result = vim
      .system({ "go", "list", "-json", "-find", "." }, {
        cwd = current_dir,
        text = true,
      })
      :wait()

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

    -- Collect all Go files (excluding test files)
    for _, file in ipairs(pkg_info.GoFiles or {}) do
      table.insert(files, pkg_dir .. "/" .. file)
    end
    for _, file in ipairs(pkg_info.CgoFiles or {}) do
      table.insert(files, pkg_dir .. "/" .. file)
    end

    return files
  end

  local function get_lsp_symbols_and_client(file_path)
    local bufnr = vim.fn.bufadd(file_path)
    vim.fn.bufload(bufnr)

    -- Ensure LSP is attached to the buffer
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if vim.tbl_isempty(clients) then
      -- Try to attach LSP to this buffer
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd("doautocmd BufReadPost")
      end)
      -- Wait a bit for LSP to attach
      vim.wait(100, function()
        clients = vim.lsp.get_clients({ bufnr = bufnr })
        return not vim.tbl_isempty(clients)
      end)
    end

    local params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr),
    }

    local results = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 2000)

    if not results or vim.tbl_isempty(results) then
      return nil, nil
    end

    -- Get the first successful response (raw LSP symbols and client)
    for client_id, result in pairs(results) do
      if result.result then
        local client = vim.lsp.get_client_by_id(client_id)
        return result.result, client
      end
    end

    return nil, nil
  end

  -- Main picker implementation
  return Snacks.picker.pick(vim.tbl_deep_extend("keep", opts or {}, {
    title = "Go Package Symbols",
    tree = true,
    -- Symbol kind filter (same as lsp_symbols)
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
    ---@param _f_opts table
    ---@param ctx snacks.picker.finder.ctx
    finder = function(_f_opts, ctx)
      -- Configure matcher for tree mode (like lsp_symbols does)
      if ctx.picker.matcher then
        ctx.picker.matcher.opts.keep_parents = true
        ctx.picker.matcher.opts.sort = false
      end

      local package_files = get_package_files()

      if not package_files or #package_files == 0 then
        vim.notify("No Go package files found, falling back to current file symbols", vim.log.levels.INFO)
        vim.schedule(function()
          Snacks.picker.lsp_symbols()
        end)
        return {}
      end

      -- Get filter configuration for current filetype
      local lsp_source = require("snacks.picker.source.lsp")
      local picker_opts = ctx.picker.opts
      local filter = picker_opts.filter[vim.bo.filetype]
      if filter == nil then
        filter = picker_opts.filter.default
      end

      -- Helper to check if a symbol kind should be included
      local function want(kind)
        kind = kind or "Unknown"
        return type(filter) == "boolean" or vim.tbl_contains(filter, kind)
      end

      -- Collect all symbols from all package files using Snacks' results_to_items
      local all_items = {}
      -- Create a single shared root for all symbols across all files
      local shared_root = { text = "", root = true }

      for _, file_path in ipairs(package_files) do
        local lsp_symbols, client = get_lsp_symbols_and_client(file_path)

        if lsp_symbols and client then
          -- Use Snacks' results_to_items to convert LSP symbols to picker items
          local items = lsp_source.results_to_items(client, lsp_symbols, {
            default_uri = vim.uri_from_fname(file_path),
            filter = function(result)
              return want(lsp_source.symbol_kind(result.kind))
            end,
          })

          -- Re-parent top-level symbols to the shared root
          -- results_to_items creates its own root, so we need to replace it
          for _, item in ipairs(items) do
            item.tree = true
            -- If this item's parent has root = true, it's a top-level symbol
            if item.parent and item.parent.root then
              item.parent = shared_root
            end
          end

          vim.list_extend(all_items, items)
        end
      end

      -- Fix 'last' flags - only the actual last child of each parent should have last = true
      -- Now that all top-level symbols share the same parent, this will work correctly
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
    format = "lsp_symbol", -- Use Snacks' native formatter
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
