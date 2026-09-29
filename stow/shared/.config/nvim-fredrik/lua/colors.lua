-- Color utility functions for highlight overrides.

local M = {}

---@param hex string
---@return number, number, number
local function hex_to_rgb(hex)
  hex = tostring(hex):gsub("#", "")
  local r = tonumber("0x" .. hex:sub(1, 2)) --[[@as number]]
  local g = tonumber("0x" .. hex:sub(3, 4)) --[[@as number]]
  local b = tonumber("0x" .. hex:sub(5, 6)) --[[@as number]]
  return r, g, b
end

---@param r number
---@param g number
---@param b number
---@return string
local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

---@param color1 string Hex color
---@param color2 string Hex color
---@param percentage number 0-100
---@return string Hex color
function M.blend(color1, color2, percentage)
  local r1, g1, b1 = hex_to_rgb(color1)
  local r2, g2, b2 = hex_to_rgb(color2)
  local r = r1 + (r2 - r1) * (percentage / 100)
  local g = g1 + (g2 - g1) * (percentage / 100)
  local b = b1 + (b2 - b1) * (percentage / 100)
  return rgb_to_hex(r, g, b)
end

return M
