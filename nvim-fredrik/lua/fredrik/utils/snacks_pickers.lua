local M = {}

---@param picker snacks.Picker
---@param cmd_name? string
local function run_picker_system(picker, cmd_name)
  local ns = vim.api.nvim_create_namespace 'run_picker_system'
  ---@param cmd string[]
  ---@param opts? vim.SystemOpts
  ---@param on_exit? fun(out: vim.SystemCompleted)
  ---@return vim.SystemObj
  return function(cmd, opts, on_exit)
    on_exit = on_exit or function() end
    local timer = assert(vim.uv.new_timer())
    local cmd_text = cmd_name or table.concat(cmd, ' ')
    local extmark_id = 999
    timer:start(
      0,
      80,
      vim.schedule_wrap(function()
        local virtual_text = {}
        table.insert(virtual_text, { cmd_text, 'SnacksPickerDimmed' })
        table.insert(virtual_text, { ' ' })
        table.insert(virtual_text, { Snacks.util.spinner() .. ' ', 'SnacksPickerSpinner' })
        vim.api.nvim_buf_set_extmark(picker.input.win.buf, ns, 0, 0, {
          id = extmark_id,
          virt_text = virtual_text,
          virt_text_pos = 'right_align',
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
  return Snacks.picker.pick(vim.tbl_deep_extend('keep', opts or {}, {
    title = 'Pull Requests',
    finder = function(f_opts, ctx)
      return require('snacks.picker.source.proc').proc({
        f_opts,
        {
          cmd = 'gh',
          args = { 'pr', 'list', '--json', 'number,title,body', '--jq', '.[] | [.number, .title, .body] | @tsv' },
          transform = function(item) ---@param item snacks.picker.finder.Item
            local split = vim.split(item.text, '\t')
            item.pr_number = tonumber(split[1])
            item.pr_title = split[2]
            item.pr_body = split[3]
          end,
        },
      }, ctx)
    end,
    confirm = function(picker, item)
      run_picker_system(picker)({ 'gh', 'pr', 'checkout', item.pr_number }, { timeout = 10000 }, function(out)
        picker:close()
        vim.schedule(function()
          Snacks.notify.info(out.stderr)
        end)
      end)
    end,
    format = function(item)
      local res = {}
      table.insert(res, { '#' .. item.pr_number, 'Function' })
      table.insert(res, { ' ' })
      table.insert(res, { item.pr_title })
      return res
    end,
    preview = function(ctx)
      ctx.preview:highlight { ft = 'markdown' }
      ctx.preview:set_lines(vim.split(ctx.item.pr_body, [[\r\n]]))
    end,
  } --[[@as snacks.picker.Config]]))
end

return M
