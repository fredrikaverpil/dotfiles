local M = {}

---@param hex string
---@return number, number, number
local function hex_to_rgb(hex)
  hex = tostring(hex):gsub("#", "")
  return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

---@param r number
---@param g number
---@param b number
---@return string
local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

---@param r number
---@param g number
---@param b number
---@return number, number, number
local function rgb_to_hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, l = 0, 0, (max + min) / 2

  if max == min then
    h, s = 0, 0 -- achromatic
  else
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)
    if max == r then h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end
  return h * 360, s * 100, l * 100
end

---@param h number
---@param s number
---@param l number
---@return number, number, number
local function hsl_to_rgb(h, s, l)
  h, s, l = h / 360, s / 100, l / 100
  local r, g, b
  if s == 0 then
    r, g, b = l, l, l
  else
    local function hue2rgb(p, q, t)
      if t < 0 then t = t + 1 end
      if t > 1 then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end
    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end
  return r * 255, g * 255, b * 255
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

---@param color string Hex color
---@param percentage number 0-100
---@return string Hex color
function M.lighten(color, percentage)
  return M.blend(color, "#ffffff", percentage)
end

---@param color string Hex color
---@param percentage number 0-100
---@return string Hex color
function M.darken(color, percentage)
  return M.blend(color, "#000000", percentage)
end

---@param color string Hex color
---@param percentage number 0-100
---@return string Hex color
function M.saturate(color, percentage)
  local r, g, b = hex_to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)
  s = math.min(100, s + percentage)
  return rgb_to_hex(hsl_to_rgb(h, s, l))
end

---@param color string Hex color
---@param percentage number 0-100
---@return string Hex color
function M.desaturate(color, percentage)
  local r, g, b = hex_to_rgb(color)
  local h, s, l = rgb_to_hsl(r, g, b)
  s = math.max(0, s - percentage)
  return rgb_to_hex(hsl_to_rgb(h, s, l))
end

---@param name string Highlight group name
---@return {fg: string}|nil
function M.fgcolor(name)
  local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name, link = false })
  local fg = hl and hl.fg
  return fg and { fg = string.format("#%06x", fg) } or nil
end

return M
