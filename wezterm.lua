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

-- colorschemes
-- https://wezfurlong.org/wezterm/colorschemes/
-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end

function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "tokyonight_moon"
  else
    return "tokyonight_day"
  end
end

config.color_scheme = scheme_for_appearance(get_appearance())

-- title bar
config.window_decorations = "RESIZE"

-- tab config
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

return config
