-- The optional host package supplies persistent scale defaults. Keep the
-- fallback here: this shared config is also stowed to Linux hosts without a
-- monitors.lua. Hyprland only watches this entry file, so a change to the
-- host file takes effect on the next explicit reload or compositor start.
local monitor_config = { scale = 1, gdkScale = 1 }
local monitor_config_file = os.getenv("HOME") .. "/.config/hypr/monitors.lua"
local monitor_config_loader = loadfile(monitor_config_file)
if monitor_config_loader then
  local ok, config = pcall(monitor_config_loader)
  if ok and type(config) == "table" then
    if type(config.scale) == "number" and config.scale > 0 then monitor_config.scale = config.scale end
    if type(config.gdkScale) == "number" and config.gdkScale > 0 then monitor_config.gdkScale = config.gdkScale end
  end
end

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = monitor_config.scale })
hl.env("GDK_SCALE", tostring(monitor_config.gdkScale))

-- macOS-like black pointer with a white outline, loaded from the stowed
-- ~/.local/share/icons/macOS-hypr theme. Source:
-- https://github.com/6ooker/apple_hyprcursor
hl.env("HYPRCURSOR_THEME", "macOS-hypr")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
  },

  decoration = {
    rounding = 8,
  },

  -- 2 is Hyprland's right/bottom insertion direction. This matches Omarchy;
  -- leave preserve_split at its default because that controls manual resizing,
  -- not where a new client opens.
  dwindle = {
    force_split = 2,
  },

  input = {
    kb_layout = "us",
  },

  -- virtio-gpu exposes no cursor plane
  cursor = {
    no_hardware_cursors = true,
  },

  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
    -- Both default to false, which leaves a blanked output with no way back
    -- from the keyboard: the screen reads as a hung machine rather than a dark
    -- one, and nothing but `hyprctl dispatch dpms on` over SSH recovers it.
    -- The compositor owns the wake, so it still works when the shell that
    -- blanked the output is gone.
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Match Omarchy's look and feel: workspace changes are instant, while the
-- global and window animation settings still animate opening and closing.
hl.animation({ leaf = "workspaces", enabled = false })

-- Tagging a window "noidle" holds the whole session awake, per Omarchy's
-- default/hypr/apps/system.lua. hyprctl -j clients reports the result as
-- inhibitingIdle, which is what the bind below reads back. The tag is window
-- state, so it is gone on close or reboot; an app that always needs this wants
-- its own rule matched on class with idle_inhibit = "fullscreen" instead.
hl.window_rule({ match = { tag = "noidle" }, idle_inhibit = "always" })

-- Toggling the tag is otherwise invisible, and Omarchy's equivalent
-- affordance is a bar indicator we have not ported.
local stay_awake = table.concat({
  [[hyprctl dispatch 'hl.dsp.window.tag({ tag = "noidle" })' >/dev/null;]],
  [[hyprctl -j activewindow | jq -e .inhibitingIdle >/dev/null]],
  [[&& notify-send -u low "Stay awake" "On for this window"]],
  [[|| notify-send -u low "Stay awake" "Off for this window"]],
}, " ")

-- Every bind goes through this rather than hl.bind directly. `hyprctl binds`
-- reports Lua binds with an empty key whenever the chord uses code:NN, so this
-- file is the only place the chord still exists in readable form: the
-- cheatsheet reads what is recorded here, not hyprctl. A bare hl.bind()
-- registers with Hyprland but stays invisible in the cheatsheet.
local binds = {}

local function bind(keys, description, dispatcher, opts)
  opts = opts or {}
  local options = { description = description }
  for key, value in pairs(opts) do
    if key ~= "display" then
      options[key] = value
    end
  end
  binds[#binds + 1] = (opts.display or keys) .. "\t" .. description
  hl.bind(keys, dispatcher, options)
end

-- Omarchy's chords and wording, minus what needs a binary or a monitor this
-- host does not have; nix/hosts/wily-vm/CLAUDE.md lists what was dropped.
--
-- Source order is cheatsheet display order. Reordering for tidiness reorders
-- the cheatsheet.
--
-- The block runs under pcall because a runtime error in any one bind would
-- otherwise stop the file dead: every later bind would go unregistered and the
-- recorder below would never run, blanking the cheatsheet as well. Hyprland
-- reports such an error nowhere but the on-screen overlay.
local ok, err = pcall(function()
  -- Applications
  bind("SUPER + RETURN", "Terminal", hl.dsp.exec_cmd("ghostty"))
  bind("SUPER + SHIFT + RETURN", "Browser", hl.dsp.exec_cmd("uwsm-app -- zen-beta.desktop"))
  bind("SUPER + SHIFT + B", "Browser", hl.dsp.exec_cmd("uwsm-app -- zen-beta.desktop"))
  bind("SUPER + SHIFT + N", "Editor", hl.dsp.exec_cmd("ghostty -e nvim"))

  -- Shell
  bind("SUPER + SPACE", "Menu", hl.dsp.exec_cmd("qs ipc call menu toggle"))
  bind("SUPER + ALT + SPACE", "Apps menu", hl.dsp.exec_cmd("qs ipc call menu level apps"))
  bind("SUPER + ESCAPE", "System menu", hl.dsp.exec_cmd("qs ipc call menu level system"))
  bind("SUPER + K", "Keybindings", hl.dsp.exec_cmd("qs ipc call menu level learn.keybindings"))
  bind("SUPER + CTRL + SPACE", "Background switcher", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))
  bind("SUPER + SHIFT + CTRL + SPACE", "Theme menu", hl.dsp.exec_cmd("qs ipc call menu level style.theme"))
  bind("SUPER + comma", "Dismiss latest notification", hl.dsp.exec_cmd("qs ipc call notifications dismissOne"))
  bind("SUPER + SHIFT + comma", "Dismiss all notifications", hl.dsp.exec_cmd("qs ipc call notifications dismissAll"))
  bind("SUPER + CTRL + comma", "Toggle Do Not Disturb", hl.dsp.exec_cmd("qs ipc call notifications toggleDnd"))
  bind("SUPER + ALT + comma", "Invoke latest notification", hl.dsp.exec_cmd("qs ipc call notifications invokeLast"))
  bind("SUPER + SHIFT + ALT + comma", "Open notification history", hl.dsp.exec_cmd("qs ipc call notifications showHistory"))
  bind("SUPER + CTRL + N", "Toggle nightlight", hl.dsp.exec_cmd("qs ipc call nightlight toggle"))
  bind("SUPER + CTRL + D", "Display settings", hl.dsp.exec_cmd("qs ipc call display toggle"))
  bind("SUPER + CTRL + W", "Network settings", hl.dsp.exec_cmd("qs ipc call network toggle"))
  bind("SUPER + CTRL + A", "Audio settings", hl.dsp.exec_cmd("qs ipc call audio toggle"))
  bind("SUPER + CTRL + I", "Toggle idle locking", hl.dsp.exec_cmd("qs ipc call idle toggle"))
  bind("SUPER + CTRL + ALT + I", "Keep this window awake", hl.dsp.exec_cmd(stay_awake))
  bind("SUPER + CTRL + L", "Lock system", hl.dsp.exec_cmd("qs ipc call lock lock"))

  -- Windows
  bind("SUPER + W", "Close window", hl.dsp.window.close())
  bind("SUPER + Q", "Close window", hl.dsp.window.close())
  bind("SUPER + J", "Toggle window split", hl.dsp.layout("togglesplit"))
  bind("SUPER + P", "Pseudo window", hl.dsp.window.pseudo())
  bind("SUPER + T", "Toggle window floating/tiling", hl.dsp.window.float({ action = "toggle" }))
  bind("SUPER + F", "Full screen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
  bind("SUPER + ALT + F", "Full width", hl.dsp.window.fullscreen({ mode = "maximized" }))

  bind("SUPER + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
  bind("SUPER + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
  bind("SUPER + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
  bind("SUPER + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

  bind("SUPER + SHIFT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
  bind("SUPER + SHIFT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
  bind("SUPER + SHIFT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
  bind("SUPER + SHIFT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

  bind("ALT + TAB", "Focus on next window", hl.dsp.window.cycle_next())
  bind("ALT + SHIFT + TAB", "Focus on previous window", hl.dsp.window.cycle_next({ next = false }))
  bind("ALT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())
  bind("ALT + SHIFT + TAB", "Reveal active window on top", hl.dsp.window.bring_to_top())

  -- Workspaces. code:10..19 are the physical 1..0 keys, so these survive a
  -- layout change; the display string is what the cheatsheet shows instead.
  for ws = 1, 10 do
    local key = "code:" .. (ws + 9)
    local digit = ws == 10 and "0" or tostring(ws)
    bind("SUPER + " .. key, "Switch to workspace " .. ws, hl.dsp.focus({ workspace = tostring(ws) }), { display = "SUPER + " .. digit })
    bind(
      "SUPER + SHIFT + " .. key,
      "Move window to workspace " .. ws,
      hl.dsp.window.move({ workspace = tostring(ws) }),
      { display = "SUPER + SHIFT + " .. digit }
    )
    bind(
      "SUPER + SHIFT + ALT + " .. key,
      "Move window silently to workspace " .. ws,
      hl.dsp.window.move({ workspace = tostring(ws), follow = false }),
      { display = "SUPER + SHIFT + ALT + " .. digit }
    )
  end

  bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
  bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
  bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

  bind("SUPER + S", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
  bind("SUPER + grave", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"), { display = "SUPER + ~" })
  bind("SUPER + ALT + S", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
  bind(
    "SUPER + SHIFT + grave",
    "Move window to scratchpad",
    hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }),
    { display = "SUPER + SHIFT + ~" }
  )

  -- Resize. code:20/21 are the physical minus/equal keys.
  bind("SUPER + code:20", "Expand window left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { display = "SUPER + MINUS" })
  bind("SUPER + code:21", "Shrink window left", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { display = "SUPER + EQUAL" })
  bind("SUPER + SHIFT + code:20", "Shrink window up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { display = "SUPER + SHIFT + MINUS" })
  bind("SUPER + SHIFT + code:21", "Expand window down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { display = "SUPER + SHIFT + EQUAL" })

  bind("SUPER + ALT + code:20", "Expand window left a little", hl.dsp.window.resize({ x = -25, y = 0, relative = true }), { display = "SUPER + ALT + MINUS" })
  bind("SUPER + ALT + code:21", "Shrink window left a little", hl.dsp.window.resize({ x = 25, y = 0, relative = true }), { display = "SUPER + ALT + EQUAL" })
  bind("SUPER + SHIFT + ALT + code:20", "Shrink window up a little", hl.dsp.window.resize({ x = 0, y = -25, relative = true }), { display = "SUPER + SHIFT + ALT + MINUS" })
  bind("SUPER + SHIFT + ALT + code:21", "Expand window down a little", hl.dsp.window.resize({ x = 0, y = 25, relative = true }), { display = "SUPER + SHIFT + ALT + EQUAL" })

  bind("SUPER + CTRL + code:20", "Expand window left a lot", hl.dsp.window.resize({ x = -300, y = 0, relative = true }), { display = "SUPER + CTRL + MINUS" })
  bind("SUPER + CTRL + code:21", "Shrink window left a lot", hl.dsp.window.resize({ x = 300, y = 0, relative = true }), { display = "SUPER + CTRL + EQUAL" })
  bind("SUPER + CTRL + SHIFT + code:20", "Shrink window up a lot", hl.dsp.window.resize({ x = 0, y = -300, relative = true }), { display = "SUPER + CTRL + SHIFT + MINUS" })
  bind("SUPER + CTRL + SHIFT + code:21", "Expand window down a lot", hl.dsp.window.resize({ x = 0, y = 300, relative = true }), { display = "SUPER + CTRL + SHIFT + EQUAL" })

  -- Groups
  bind("SUPER + G", "Toggle window grouping", hl.dsp.group.toggle())
  bind("SUPER + ALT + G", "Move active window out of group", hl.dsp.window.move({ out_of_group = true }))
  bind("SUPER + ALT + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
  bind("SUPER + ALT + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
  bind("SUPER + ALT + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
  bind("SUPER + ALT + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))
  bind("SUPER + ALT + TAB", "Next window in group", hl.dsp.group.next())
  bind("SUPER + ALT + SHIFT + TAB", "Previous window in group", hl.dsp.group.prev())
  bind("SUPER + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
  bind("SUPER + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

  for index = 1, 5 do
    bind(
      "SUPER + ALT + code:" .. (index + 9),
      "Switch to group window " .. index,
      hl.dsp.group.active({ index = index }),
      { display = "SUPER + ALT + " .. index }
    )
  end

  bind("SUPER + mouse_down", "Scroll active workspace forward", hl.dsp.focus({ workspace = "e+1" }))
  bind("SUPER + mouse_up", "Scroll active workspace backward", hl.dsp.focus({ workspace = "e-1" }))
  bind("SUPER + ALT + mouse_down", "Next window in group", hl.dsp.group.next())
  bind("SUPER + ALT + mouse_up", "Previous window in group", hl.dsp.group.prev())

  bind("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { display = "SUPER + LEFT MOUSE BUTTON", mouse = true })
  bind("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { display = "SUPER + RIGHT MOUSE BUTTON", mouse = true })

  bind("SUPER + SHIFT + E", "Exit Hyprland", hl.dsp.exit())
end)

if not ok then
  hl.notification.create({ text = "hyprland.lua: " .. tostring(err), timeout = 15000 })
end

-- Written atomically: Hyprland re-runs this file on every config change, and
-- the cheatsheet may be reading it while that happens. niri's config.kdl
-- extracts the same two columns into the same file, so the cheatsheet reads
-- one path under either compositor.
local path = os.getenv("HOME") .. "/.local/state/wm-binds.tsv"
local out = io.open(path .. ".tmp", "w")
if out then
  out:write(table.concat(binds, "\n"), "\n")
  out:close()
  os.rename(path .. ".tmp", path)
end
