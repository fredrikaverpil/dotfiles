local M = {}

local function is_table(t)
  return type(t) == "table"
end

local function is_array(t)
  if not is_table(t) then
    return false
  end
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count == #t
end

function M.deep_merge(t1, t2)
  if not is_table(t1) then
    return t2
  end
  if not is_table(t2) then
    return t2
  end

  local result = {}

  -- Copy all fields from t1
  for k, v in pairs(t1) do
    result[k] = v
  end

  -- Merge t2 into result
  for k, v in pairs(t2) do
    if is_table(v) and is_table(result[k]) then
      if is_array(v) and is_array(result[k]) then
        -- Merge arrays by concatenating
        result[k] = vim.list_extend(vim.list_extend({}, result[k]), v)
      else
        -- Recursively merge tables
        result[k] = M.deep_merge(result[k], v)
      end
    else
      result[k] = v
    end
  end

  return result
end

return M
