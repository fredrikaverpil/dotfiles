local M = {}

local function home_parent()
  return vim.fs.dirname(vim.fs.normalize("~"))
end

function M.upward(names, opts)
  opts = opts or {}

  return vim.fs.find(names, {
    path = opts.path,
    upward = true,
    type = opts.type or "file",
    limit = opts.limit or 1,
    stop = opts.stop or home_parent(),
  })
end

function M.file_upward(names, opts)
  return M.upward(names, opts)[1]
end

function M.dir_upward(names, opts)
  local file = M.file_upward(names, opts)
  if file == nil then
    return nil
  end
  return vim.fn.fnamemodify(file, ":h")
end

return M
