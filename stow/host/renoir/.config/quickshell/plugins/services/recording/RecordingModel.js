// The camera is composited into the bottom-right corner of the recording.
function captureSource(monitor, camera) {
  return camera
    ? "monitor:" + monitor + "|v4l2:" + camera + ";halign=end;valign=end;width=20%"
    : monitor
}

// One merged track: most players only play the first of several.
function audioSource(mic, desktop) {
  var parts = []
  if (desktop) parts.push("default_output")
  if (mic) parts.push(mic)
  return parts.join("|")
}

function command(options, file) {
  var args = ["gpu-screen-recorder", "-w", captureSource(options.monitor, options.camera), "-f", "30"]
  var audio = audioSource(options.mic, options.desktop)
  if (audio) args.push("-a", audio, "-ac", "aac")
  args.push("-o", file)
  return args
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
