var sustainMilliseconds = 30000

// Most severe first.
var alertKinds = [
  { kind: "memory", icon: "\u{F035B}", label: "Memory low" },
  { kind: "temperature", icon: "\u{F050F}", label: "CPU hot" },
  { kind: "cpu", icon: "\u{F0EE0}", label: "CPU busy" },
  { kind: "upload", icon: "\u{F0552}", label: "Uploading" },
]

// Tctl throttles at 105 °C; big downloads are routine, big uploads are not.
// Swap use is ignored: swapped pages linger long after the pressure is gone.
function conditions(sample) {
  return {
    memory: sample.memory.total > 0 && sample.memory.available < sample.memory.total * 0.1,
    temperature: sample.temperature >= 90,
    cpu: sample.cpu >= 80,
    upload: sample.txRate >= 2000000,
  }
}

// Start of each condition's current run; 0 while it is not met.
function since(previous, met, now) {
  var next = {}
  Object.keys(met).forEach(function(kind) {
    next[kind] = met[kind] ? (previous[kind] || now) : 0
  })
  return next
}

function sustained(starts, now) {
  return alertKinds.filter(function(alert) {
    return starts[alert.kind] > 0 && now - starts[alert.kind] >= sustainMilliseconds
  })
}

// Total and idle jiffies of the aggregate "cpu" line; null when missing.
function parseCpuTimes(text) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var fields = lines[i].trim().split(/\s+/)
    if (fields[0] !== "cpu") continue
    // user nice system idle iowait irq softirq steal; guest is already in user.
    var values = fields.slice(1, 9).map(function(value) { return Number(value) || 0 })
    var total = values.reduce(function(sum, value) { return sum + value }, 0)
    return { total: total, idle: values[3] + values[4] }
  }
  return null
}

// Busy percent between two samples; 0 without both.
function cpuUsage(previous, current) {
  if (!previous || !current) return 0
  var total = current.total - previous.total
  var idle = current.idle - previous.idle
  return total > 0 ? Math.max(0, Math.min(100, (total - idle) / total * 100)) : 0
}

// kB values.
function parseMemory(text) {
  var values = {}
  String(text || "").split("\n").forEach(function(line) {
    var match = /^(\w+):\s+(\d+)/.exec(line)
    if (match) values[match[1]] = Number(match[2])
  })
  return { total: values.MemTotal || 0, available: values.MemAvailable || 0 }
}

// Interface of the lowest-metric default route in /proc/net/route.
function defaultInterface(text) {
  var best = ""
  var bestMetric = Infinity
  String(text || "").split("\n").slice(1).forEach(function(line) {
    var fields = line.trim().split(/\s+/)
    if (fields[1] !== "00000000" || fields[7] !== "00000000") return
    var metric = Number(fields[6])
    if (metric < bestMetric) {
      best = fields[0]
      bestMetric = metric
    }
  })
  return best
}

// Cumulative transmitted bytes of one interface in /proc/net/dev.
function transmittedBytes(text, name) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var separator = lines[i].indexOf(":")
    if (separator < 0 || lines[i].slice(0, separator).trim() !== name) continue
    return Number(lines[i].slice(separator + 1).trim().split(/\s+/)[8])
  }
  return null
}

// Bytes per second; a counter reset reads as 0.
function rate(previous, current, seconds) {
  if (!(seconds > 0) || !(current >= previous)) return 0
  return (current - previous) / seconds
}
