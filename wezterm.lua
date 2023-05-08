local wezterm = require("wezterm")
local config = {}

-- https://wezfurlong.org/wezterm/config/files.html

config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"JetBrains Mono Nerd Font",
})

config.color_scheme = "Catppuccin Mocha"

return config
