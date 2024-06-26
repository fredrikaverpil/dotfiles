local wezterm = require("wezterm")
local config = {}
local is_windows = os.getenv("OS") == "Windows_NT"

-- https://wezfurlong.org/wezterm/config/files.html

config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400

-- font
-- https://www.jetbrains.com/lp/mono
-- https://github.com/ryanoasis/nerd-fonts/releases
-- https://fonts.google.com/noto/specimen/Noto+Color+Emoji
local disable_ligatures = { "calt=0", "clig=0", "liga=0" }
config.font = wezterm.font_with_fallback({
  { family = "Berkeley Mono" },
  { family = "JetBrains Mono", harfbuzz_features = disable_ligatures },
  -- { family = "JetBrainsMono Nerd Font", harfbuzz_features = disable_ligatures },
  { family = "Symbols Nerd Font Mono" },
  { family = "Noto Color Emoji" },
  { family = "Noto Emoji" },
})

if is_windows then
  config.font_size = 10
else
  config.font_size = 14
end

-- colorschemes
-- https://wezfurlong.org/wezterm/colorschemes/
-- wezterm.gui is not available to the mux server, so take care to
-- do something reasonable when this config is evaluated by the mux
local function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return "Dark"
end

local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return "Tokyo Night Moon"
  else
    return "dayfox"
    -- return "Tokyo Night Day"
  end
end

config.color_scheme = scheme_for_appearance(get_appearance())

-- title bar
-- NOTE: For Windows/WSL, the "RESIZE" setting doesn't allow for moving around the window
if is_windows then
  config.window_decorations = "TITLE | RESIZE"
else
  config.window_decorations = "RESIZE"
end

-- https://wezfurlong.org/wezterm/config/lua/config/window_padding.html
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}

-- https://wezfurlong.org/wezterm/config/appearance.html
config.window_background_opacity = 1.0 -- 0.4
config.text_background_opacity = 1.0 -- 0.9

-- tab config
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- ssh hosts from ~./ssh/config
local ssh_domains = {}
for host, config_ in pairs(wezterm.enumerate_ssh_hosts()) do
  table.insert(ssh_domains, {
    -- the name can be anything you want; we're just using the hostname
    name = host,
    -- remote_address must be set to `host` for the ssh config to apply to it
    remote_address = host,

    -- if you don't have wezterm's mux server installed on the remote
    -- host, you may wish to set multiplexing = "None" to use a direct
    -- ssh connection that supports multiple panes/tabs which will close
    -- when the connection is dropped.

    -- multiplexing = "None",

    -- if you know that the remote host has a posix/unix environment,
    -- setting assume_shell = "Posix" will result in new panes respecting
    -- the remote current directory when multiplexing = "None".
    assume_shell = "Posix",
  })
end
config.ssh_domains = ssh_domains

config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_function = "EaseIn",
  fade_in_duration_ms = 150,
  fade_out_function = "EaseOut",
  fade_out_duration_ms = 150,
}
config.colors = {
  visual_bell = "#202020",
}

-- start straight into WSL
if is_windows then
  config.default_domain = "WSL:Ubuntu"
end

return config
