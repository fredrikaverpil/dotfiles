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

  -- Helper function to recursively build picker items from LSP symbols
  -- Similar to Snacks' add() function, builds items with proper parent pointers in one pass
  local function symbols_to_items(symbols, file_path, parent_item, items)
    items = items or {}

    for _, symbol in ipairs(symbols or {}) do
      local filename = vim.fn.fnamemodify(file_path, ":t")

      ---@type snacks.picker.finder.Item
      local item = {
        text = symbol.name,
        name = symbol.name,
        lsp_kind = symbol.kind,
        file = file_path,
        filename = filename,
        parent = parent_item,
        tree = true,
        pos = symbol.selectionRange and {
          symbol.selectionRange.start.line + 1,
          symbol.selectionRange.start.character,
        } or symbol.range and {
          symbol.range.start.line + 1,
          symbol.range.start.character,
        } or { 1, 0 },
      }

      table.insert(items, item)

      -- Recursively process children, passing this item as their parent
      if symbol.children then
        symbols_to_items(symbol.children, file_path, item, items)
      end
    end

    return items
  end

  -- Helper function to get LSP symbols for a file
  local function get_lsp_symbols(file_path)
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
      return {}
    end

    -- Get the first successful response (raw LSP symbols)
    for _, result in pairs(results) do
      if result.result then
        return result.result
      end
    end

    return {}
  end

  -- Main picker implementation
  return Snacks.picker.pick(vim.tbl_deep_extend("keep", opts or {}, {
    title = "Go Package Symbols",
    tree = true,
    ---@param _f_opts table
    ---@param _ctx snacks.picker.finder.ctx
    finder = function(_f_opts, _ctx)
      local package_files = get_package_files()

      if not package_files or #package_files == 0 then
        vim.notify("No Go package files found, falling back to current file symbols", vim.log.levels.INFO)
        vim.schedule(function()
          Snacks.picker.lsp_symbols()
        end)
        return {}
      end

      -- Collect all symbols from all package files
      ---@type snacks.picker.finder.Item[]
      local items = {}

      -- Create a single root for all symbols across all files (like Snacks does)
      local root = { text = "", root = true }

      for _, file_path in ipairs(package_files) do
        local lsp_symbols = get_lsp_symbols(file_path)
        -- Recursively convert LSP symbols to picker items with proper parent pointers
        symbols_to_items(lsp_symbols, file_path, root, items)
      end

      -- Fix 'last' flags - only the actual last child of each parent should have last = true
      -- This is necessary because symbols from different files share the same root parent
      local last = {} ---@type table<snacks.picker.finder.Item, snacks.picker.finder.Item>
      for _, item in ipairs(items) do
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

      return items
    end,
    format = function(item, picker)
      -- Use the same format as lsp_symbols with tree indentation
      local ret = {}

      -- Add tree indentation for hierarchical symbols
      if item.tree and item.parent then
        local indent = {}
        local icons = picker.opts.icons.tree
        local node = item
        while node and node.parent do
          local is_last, icon = node.last, ""
          if node ~= item then
            icon = is_last and "  " or icons.vertical
          else
            icon = is_last and icons.last or icons.middle
          end
          table.insert(indent, 1, icon)
          node = node.parent
        end
        ret[#ret + 1] = { table.concat(indent), "SnacksPickerTree" }
      end

      -- Add symbol icon and name with syntax highlighting
      local kind = vim.lsp.protocol.SymbolKind[item.lsp_kind] or "Unknown"
      kind = picker.opts.icons.kinds[kind] and kind or "Unknown"
      local kind_hl = "SnacksPickerIcon" .. kind
      local icon = picker.opts.icons.kinds[kind] or ""

      ret[#ret + 1] = { icon, kind_hl }
      ret[#ret + 1] = { " " }

      -- Apply syntax highlighting to the symbol name (like Snacks does)
      local name = vim.trim(item.name:gsub("\r?\n", " "))
      name = name == "" and item.detail or name
      Snacks.picker.highlight.format(item, name, ret)

      return ret
    end,
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
