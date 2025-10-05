local M = {}

function M.remove_shada_files()
  local stdpath = vim.fn.stdpath("state")
  local shada_file = stdpath .. "/shada/main.shada"
  local shada_tmp = stdpath .. "/shada/main.shada.tmp.*"

  local files_removed = 0

  -- Remove main shada file
  if vim.fn.filereadable(shada_file) == 1 then
    vim.fn.delete(shada_file)
    files_removed = files_removed + 1
  end

  -- Remove temporary shada files
  local tmp_files = vim.fn.glob(shada_tmp, false, true)
  for _, file in ipairs(tmp_files) do
    vim.fn.delete(file)
    files_removed = files_removed + 1
  end

  if files_removed > 0 then
    vim.notify("Removed " .. files_removed .. " shada file(s)", vim.log.levels.INFO)
  else
    vim.notify("No shada files found to remove", vim.log.levels.WARN)
  end
end

return M

