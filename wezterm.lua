local wezterm = require("wezterm")
local config = {}

-- https://wezfurlong.org/wezterm/config/files.html

config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "JetBrains Mono Nerd Font",
})

-- https://wezfurlong.org/wezterm/colorschemes/
-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "tokyonight_night"
config.color_scheme = "Tokyo Night (Gogh)"

return config
