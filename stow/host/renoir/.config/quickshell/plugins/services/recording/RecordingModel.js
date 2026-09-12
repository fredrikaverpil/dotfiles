// The camera is composited into the bottom-right corner of the recording.
function captureSource(monitor, region, camera) {
  var source = region ? "region" : monitor
  if (!camera) return source
  return (region ? source : "monitor:" + source) + "|v4l2:" + camera + ";halign=end;valign=end;width=20%"
}

// One merged track: most players only play the first of several.
function audioSource(mic, desktop) {
  var parts = []
  if (desktop) parts.push("default_output")
  if (mic) parts.push(mic)
  return parts.join("|")
}

function command(options, file) {
  var args = ["gpu-screen-recorder", "-w", captureSource(options.monitor, options.region, options.camera)]
  if (options.region) args.push("-region", formatRegion(options.region))
  args.push("-f", "30")
  var audio = audioSource(options.mic, options.desktop)
  if (audio) args.push("-a", audio, "-ac", "aac")
  args.push("-o", file)
  return args
}

// Regions are logical, global {x, y, width, height}; gsr scales them to pixels.
function formatRegion(rect) {
  return Math.round(rect.width) + "x" + Math.round(rect.height) + "+" + Math.round(rect.x) + "+" + Math.round(rect.y)
}

// 0x0 is valid: gsr then records the whole monitor containing the position.
function parseRegion(text) {
  var match = /^(\d+)x(\d+)\+(-?\d+)\+(-?\d+)$/.exec(String(text || "").trim())
  return match ? { x: Number(match[3]), y: Number(match[4]), width: Number(match[1]), height: Number(match[2]) } : null
}

// The screen containing the centre of rect, or null.
function screenAt(screens, rect) {
  var cx = rect.x + rect.width / 2
  var cy = rect.y + rect.height / 2
  for (var i = 0; i < screens.length; i++) {
    var s = screens[i]
    if (cx >= s.x && cx < s.x + s.width && cy >= s.y && cy < s.y + s.height) return s
  }
  return null
}

var minRegion = 16

function clampRegion(rect, screen) {
  var width = Math.max(minRegion, Math.min(screen.width, rect.width))
  var height = Math.max(minRegion, Math.min(screen.height, rect.height))
  return {
    x: Math.max(screen.x, Math.min(screen.x + screen.width - width, rect.x)),
    y: Math.max(screen.y, Math.min(screen.y + screen.height - height, rect.y)),
    width: width,
    height: height,
  }
}

// The saved region if it still fits a screen, else the centred half of the first screen.
function initialRegion(saved, screens) {
  var screen = saved && screenAt(screens, saved)
  if (screen) return clampRegion(saved, screen)
  var first = screens[0]
  return { x: first.x + first.width / 4, y: first.y + first.height / 4, width: first.width / 2, height: first.height / 2 }
}

// The same-sized region centred on the screen after the one it is on.
function nextScreenRegion(rect, screens) {
  var index = screens.indexOf(screenAt(screens, rect))
  var screen = screens[(index + 1) % screens.length]
  return clampRegion({
    x: screen.x + (screen.width - rect.width) / 2,
    y: screen.y + (screen.height - rect.height) / 2,
    width: rect.width,
    height: rect.height,
  }, screen)
}

function spanRegion(x1, y1, x2, y2) {
  return { x: Math.min(x1, x2), y: Math.min(y1, y2), width: Math.abs(x2 - x1), height: Math.abs(y2 - y1) }
}

function pad(value) { return value < 10 ? "0" + value : String(value) }

function fileName(date) {
  return "recording-" + date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
    + "_" + pad(date.getHours()) + "-" + pad(date.getMinutes()) + "-" + pad(date.getSeconds()) + ".mp4"
}

function elapsed(seconds) {
  var hours = Math.floor(seconds / 3600)
  var rest = pad(Math.floor(seconds % 3600 / 60)) + ":" + pad(seconds % 60)
  return hours > 0 ? hours + ":" + rest : rest
}

// Lines are "path|name"; V4L2 names often repeat the model after a colon.
function parseCameras(text) {
  var cameras = []
  String(text || "").split("\n").forEach(function(line) {
    var fields = line.split("|")
    if (fields.length < 2 || fields[0].indexOf("/dev/video") !== 0) return
    cameras.push({ path: fields[0], name: fields[1].split(":")[0].trim() || fields[0] })
  })
  return cameras
}

function pick(values, saved, fallback) {
  return values.indexOf(saved) >= 0 ? saved : fallback
}

function step(values, current, delta) {
  if (values.length === 0) return current
  var index = Math.max(0, values.indexOf(current))
  return values[(index + delta + values.length) % values.length]
}
