function deviceName(device) {
  return String(device.name || device.deviceName || device.address || "")
}

// Paired devices, connected first, then by name.
function pairedDevices(devices) {
  return (devices || [])
    .filter(device => device && (device.paired || device.bonded))
    .sort((a, b) => (b.connected - a.connected) || deviceName(a).localeCompare(deviceName(b)))
}

// battery is 0-1, or negative when the device reports none.
function deviceStatus(state, states, battery) {
  if (state === states.Connecting) return "Connecting…"
  if (state === states.Disconnecting) return "Disconnecting…"
  if (state !== states.Connected) return "Paired"
  return battery >= 0 ? "Connected · " + Math.round(battery * 100) + "%" : "Connected"
}

function deviceAction(state, states) {
  if (state === states.Connected) return "Disconnect"
  if (state === states.Disconnected) return "Connect"
  return ""
}

// icon is BlueZ's freedesktop icon name.
function deviceIcon(icon) {
  const name = String(icon || "")
  if (name.startsWith("audio-head")) return "󰋋"
  if (name.startsWith("audio")) return "󰓃"
  if (name === "input-keyboard") return "󰌌"
  if (name === "input-mouse" || name === "input-tablet") return "󰍽"
  if (name === "input-gaming") return "󰊴"
  if (name === "phone") return "󰏲"
  return "󰂯"
}

function barIcon(available, powered, connectedCount) {
  if (!available || !powered) return "󰂲"
  return connectedCount > 0 ? "󰂱" : "󰂯"
}
