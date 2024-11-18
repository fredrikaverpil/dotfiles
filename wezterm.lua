local wezterm = require("wezterm")

local act = wezterm.action
local mux = wezterm.mux

-- https://wezfurlong.org/wezterm/config/files.html
local config = wezterm.config_builder()

local keys = {}

-- NOTE: some help/reminders:
--
-- Add logs with wezterm.log_info("hello")
-- See logs from wezterm: CTRL+SHIFT+L
--
-- Update all plugins:
-- wezterm.plugin.update_all()

local is_windows = os.getenv("OS") == "Windows_NT"
local is_macos = os.getenv("OS") == "Darwin"

config.check_for_updates = true
config.check_for_updates_interval_seconds = 86400

local function is_on_battery()
  if is_windows then
    -- FIX: verify that this works...
    --
    -- local power_source = io.popen("powercfg /batteryreport")
    -- local power_source_content = power_source:read("*a")
    -- power_source:close()
    --
    -- local is_battery = string.find(power_source_content, "Battery")
    -- return is_battery
  elseif is_macos then
    local power_source = io.popen("pmset -g batt | grep 'AC Power'")
    local power_source_content = power_source:read("*a")
    power_source:close()

    local is_battery = string.find(power_source_content, "Battery Power")
    return is_battery
  end

  return false
end

if is_on_battery() then
  config.max_fps = 60
else
  config.max_fps = 120
end

-- font
-- https://www.jetbrains.com/lp/mono
-- https://github.com/ryanoasis/nerd-fonts/releases
-- https://fonts.google.com/noto/specimen/Noto+Color+Emoji
local disable_ligatures = { "calt=0", "clig=0", "liga=0" }
config.font = wezterm.font_with_fallback({
  { family = "Berkeley Mono" },
  -- { family = "JetBrains Mono", harfbuzz_features = disable_ligatures },
  -- { family = "JetBrainsMono Nerd Font", harfbuzz_features = disable_ligatures },
  { family = "Symbols Nerd Font Mono" },
  { family = "Noto Color Emoji" },
  { family = "Noto Emoji" },
})
-- Maple mono for italics
config.font_rules = {
  {
    intensity = "Bold",
    italic = true,
    font = wezterm.font({
      family = "Maple Mono",
      weight = "Bold",
      style = "Italic",
    }),
  },
  {
    italic = true,
    intensity = "Half",
    font = wezterm.font({
      family = "Maple Mono",
      weight = "DemiBold",
      style = "Italic",
    }),
  },
  {
    italic = true,
    intensity = "Normal",
    font = wezterm.font({
      family = "Maple Mono",
      style = "Italic",
    }),
  },
}

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
    return wezterm.gui.get_appearance() -- "Dark" or "Light"
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
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false

local function get_current_working_dir(tab)
  local current_dir = tab.active_pane and tab.active_pane.current_working_dir or { file_path = "" }
  local HOME_DIR = string.format("file://%s", os.getenv("HOME"))

  return current_dir == HOME_DIR and "." or string.gsub(current_dir.file_path, "(.*[/\\])(.*)", "%2")
end

-- tab title
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local has_unseen_output = false
  if not tab.is_active then
    for _, pane in ipairs(tab.panes) do
      if pane.has_unseen_output then
        has_unseen_output = true
        break
      end
    end
  end

  local cwd = wezterm.format({
    { Attribute = { Intensity = "Bold" } },
    { Text = get_current_working_dir(tab) },
  })

  local title = string.format(" [%s] %s", tab.tab_index + 1, cwd)

  if has_unseen_output then
    return {
      { Foreground = { Color = "#8866bb" } },
      { Text = title },
    }
  end

  return {
    { Text = title },
  }
end)

-- workspaces
wezterm.on("update-right-status", function(window, pane)
  window:set_right_status(window:active_workspace())
end)
local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")
workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"
wezterm.on("gui-startup", function(cmd)
  local dotfiles_path = wezterm.home_dir .. "/.dotfiles"
  local tab, build_pane, window = mux.spawn_window({
    workspace = "dotfiles",
    cwd = dotfiles_path,
    args = args,
  })
  build_pane:send_text("nvim\n")
  mux.set_active_workspace("dotfiles")
end)
table.insert(keys, { key = "s", mods = "CTRL|SHIFT", action = workspace_switcher.switch_workspace() })
table.insert(keys, { key = "t", mods = "CTRL|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) })
table.insert(keys, { key = "d", mods = "CTRL|SHIFT", action = act.SwitchToWorkspace({ name = "dotfiles" }) })
table.insert(keys, { key = "[", mods = "CTRL|SHIFT", action = act.SwitchWorkspaceRelative(1) })
table.insert(keys, { key = "]", mods = "CTRL|SHIFT", action = act.SwitchWorkspaceRelative(-1) })

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

-- https://wezfurlong.org/wezterm/config/lua/config/default_domain.html
if is_windows then
  -- start straight into WSL
  config.default_domain = "WSL:Ubuntu"
end

config.keys = keys
return config
