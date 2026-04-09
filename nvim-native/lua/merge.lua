--- Deep merge that appends and deduplicates lists, and recurses into dicts.
---@param base table
---@param override table
---@return table
local function merge(base, override)
  for k, v in pairs(override) do
    local bv = base[k]
    if type(v) == "table" then
      if type(bv) ~= "table" then
        base[k] = v
      elseif vim.islist(v) then
        for _, item in ipairs(v) do
          if type(item) == "table" or not vim.list_contains(bv, item) then
            table.insert(bv, item)
          end
        end
      else
        merge(bv, v)
      end
    else
      base[k] = v
    end
  end
  return base
end

return merge
