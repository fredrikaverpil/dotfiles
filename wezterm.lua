local wezterm = require("wezterm")
local config = {}

-- https://wezfurlong.org/wezterm/config/files.html

-- font
-- https://www.jetbrains.com/lp/mono
-- https://github.com/ryanoasis/nerd-fonts/releases
-- https://fonts.google.com/noto/specimen/Noto+Color+Emoji
config.font = wezterm.font_with_fallback({
  { family = "JetBrains Mono", weight = "Regular", harfbuzz_features = { "calt=0", "clig=0", "liga=0" } },
  { family = "Symbols Nerd Font Mono" },
  { family = "Noto Color Emoji" },
})

-- https://wezfurlong.org/wezterm/colorschemes/
-- config.color_scheme = "Catppuccin Mocha"
config.color_scheme = "tokyonight_night"

-- title bar
config.window_decorations = "RESIZE"

-- tab config
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

return config
