hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
  },

  decoration = {
    rounding = 8,
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
  },
})

hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("ghostty"), { description = "Terminal" })
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { description = "App launcher" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER + V", hl.dsp.window.float(), { description = "Toggle floating" })
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Full screen" })
hl.bind("SUPER + SHIFT + E", hl.dsp.exit(), { description = "Exit Hyprland" })

for key, dir in pairs({ H = "l", J = "d", K = "u", L = "r" }) do
  hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = dir }), { description = "Focus " .. dir })
end

-- code:10..19 are the physical 1..0 keys, so these survive a layout change.
for ws = 1, 10 do
  local key = "code:" .. (ws + 9)
  hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = tostring(ws) }), { description = "Workspace " .. ws })
  hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(ws) }), { description = "Move to workspace " .. ws })
end
