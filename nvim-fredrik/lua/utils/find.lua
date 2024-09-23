M = {}

function M.find_file(filename, excluded_dirs)
  if not excluded_dirs then
    excluded_dirs = { ".git", "node_modules", ".venv" }
  end
  local exclude_str = ""
  for _, dir in ipairs(excluded_dirs) do
    exclude_str = exclude_str .. " --exclude " .. dir
  end
  local command = "fd --hidden --no-ignore" .. exclude_str .. " '" .. filename .. "' " .. vim.fn.getcwd() .. " | head -n 1"
  local file = io.popen(command):read("*l")
  local path = file and file or nil

  return path
end

--- Find a file upwards in the directory tree and return its path, if found.
--- @param filenames table A list of filenames to search for
--- @param start_path string
--- @return string | nil
function M.find_file_upwards(filenames, start_path)
  local os_path_sep = package.config:sub(1, 1) -- "/" on Unix, "\" on Windows

  -- Ensure start_path is a directory
  local start_dir = vim.fn.isdirectory(start_path) == 1 and start_path or vim.fn.fnamemodify(start_path, ":h")
  local home_dir = vim.fn.expand("$HOME")

  while start_dir ~= home_dir do
    for _, filename in ipairs(filenames) do
      -- logger.debug("Searching for " .. filename .. " in " .. start_dir)

      local try_path = start_dir .. os_path_sep .. filename
      if vim.fn.filereadable(try_path) == 1 then
        -- logger.debug("Found " .. filename .. " at " .. try_path)
        return try_path
      end
    end

    -- Go up one directory
    start_dir = vim.fn.fnamemodify(start_dir, ":h")
  end

  return nil
end

return M
