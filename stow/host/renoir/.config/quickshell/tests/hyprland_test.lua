local config_path = assert(arg[1], "missing hyprland.lua path")
local expected_scale = tonumber((assert(arg[2], "missing expected scale")))
local expected_gdk_scale = assert(arg[3], "missing expected GDK scale")

local captured = { monitors = {}, env = {}, binds = {}, notifications = {} }

local function dispatcher(name)
  return function(options)
    return { name = name, options = options }
  end
end

hl = {
  monitor = function(options) table.insert(captured.monitors, options) end,
  env = function(name, value) captured.env[name] = value end,
  config = function() end,
  animation = function() end,
  window_rule = function() end,
  bind = function(keys, action, options)
    table.insert(captured.binds, { keys = keys, action = action, options = options })
  end,
  notification = {
    create = function(options) table.insert(captured.notifications, options) end,
  },
  dsp = {
    exec_cmd = dispatcher("exec_cmd"),
    layout = dispatcher("layout"),
    focus = dispatcher("focus"),
    exit = dispatcher("exit"),
    window = {
      close = dispatcher("window.close"),
      cycle_next = dispatcher("window.cycle_next"),
      bring_to_top = dispatcher("window.bring_to_top"),
      pseudo = dispatcher("window.pseudo"),
      float = dispatcher("window.float"),
      fullscreen = dispatcher("window.fullscreen"),
      swap = dispatcher("window.swap"),
      move = dispatcher("window.move"),
      resize = dispatcher("window.resize"),
      drag = dispatcher("window.drag"),
    },
    workspace = {
      toggle_special = dispatcher("workspace.toggle_special"),
    },
    group = {
      toggle = dispatcher("group.toggle"),
      next = dispatcher("group.next"),
      prev = dispatcher("group.prev"),
      active = dispatcher("group.active"),
    },
  },
}

assert(loadfile(config_path))()
assert(#captured.notifications == 0, captured.notifications[1] and captured.notifications[1].text
  or "Hyprland configuration did not register all binds")
assert(#captured.monitors == 1, "expected one initial monitor declaration")
assert(captured.monitors[1].scale == expected_scale, "unexpected monitor scale")
assert(captured.env.GDK_SCALE == expected_gdk_scale, "unexpected GDK scale")

local home = assert(os.getenv("HOME"), "HOME is not set")
local binds_path = home .. "/.local/state/wm-binds.tsv"
local file = assert(io.open(binds_path, "r"), "bind writer did not create TSV")
local lines = {}
for line in file:lines() do table.insert(lines, line) end
file:close()

assert(#lines == #captured.binds, "bind TSV does not match registered bind count")
assert(lines[1] == "SUPER + RETURN\tTerminal", "first bind changed")

local workspace_ten = false
for _, line in ipairs(lines) do
  if line == "SUPER + 0\tSwitch to workspace 10" then workspace_ten = true end
end
assert(workspace_ten, "workspace 10 bind is missing")
