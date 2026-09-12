var historyLength = 60

// Total and idle jiffies for "cpu" (index 0) and each "cpuN" line.
function parseCpuTimes(text) {
  var times = []
  String(text || "").split("\n").forEach(function(line) {
    var fields = line.trim().split(/\s+/)
    if (!/^cpu\d*$/.test(fields[0])) return
    // user nice system idle iowait irq softirq steal; guest is already in user.
    var values = fields.slice(1, 9).map(function(value) { return Number(value) || 0 })
    var total = values.reduce(function(sum, value) { return sum + value }, 0)
    times.push({ total: total, idle: values[3] + values[4] })
  })
  return times
}

// Busy percent per entry between two samples; empty when they do not line up.
function cpuUsage(previous, current) {
  if (!previous || previous.length !== current.length) return []
  return current.map(function(now, index) {
    var total = now.total - previous[index].total
    var idle = now.idle - previous[index].idle
    return total > 0 ? Math.max(0, Math.min(100, (total - idle) / total * 100)) : 0
  })
}

// kB values.
function parseMemory(text) {
  var values = {}
  String(text || "").split("\n").forEach(function(line) {
    var match = /^(\w+):\s+(\d+)/.exec(line)
    if (match) values[match[1]] = Number(match[2])
  })
  return {
    total: values.MemTotal || 0,
    available: values.MemAvailable || 0,
    swapTotal: values.SwapTotal || 0,
    swapFree: values.SwapFree || 0,
  }
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

// Cumulative byte counters of one interface in /proc/net/dev.
function interfaceBytes(text, name) {
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var separator = lines[i].indexOf(":")
    if (separator < 0 || lines[i].slice(0, separator).trim() !== name) continue
    var fields = lines[i].slice(separator + 1).trim().split(/\s+/).map(Number)
    return { rx: fields[0], tx: fields[8] }
  }
  return null
}

// Bytes per second; a counter reset reads as 0.
function rate(previous, current, seconds) {
  if (!(seconds > 0) || !(current >= previous)) return 0
  return (current - previous) / seconds
}

// Rows after the last header of `top -b`: its first iteration averages each
// process over its lifetime.
function parseTop(text, limit) {
  var lines = String(text || "").split("\n")
  var header = -1
  for (var i = lines.length - 1; i >= 0 && header < 0; i--) {
    if (/^\s*PID\s/.test(lines[i])) header = i
  }
  if (header < 0) return []
  var processes = []
  for (var j = header + 1; j < lines.length && processes.length < limit; j++) {
    var fields = lines[j].trim().split(/\s+/)
    if (fields.length < 12) continue
    processes.push({
      pid: Number(fields[0]),
      cpu: Number(fields[8].replace(",", ".")),
      memory: Number(fields[9].replace(",", ".")),
      // Nix wrappers show as ".name-wrapped", truncated to 15 characters.
      name: fields.slice(11).join(" ").replace(/^\./, "").replace(/-wrap\w*$/, ""),
    })
  }
  return processes
}

function formatRate(bytesPerSecond) {
  var units = ["B/s", "kB/s", "MB/s", "GB/s"]
  var value = Math.max(0, Number(bytesPerSecond) || 0)
  var unit = 0
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000
    unit++
  }
  return (unit === 0 ? Math.round(value) : value.toFixed(value < 10 ? 1 : 0)) + " " + units[unit]
}

function formatUsage(usedKiB, totalKiB) {
  return (usedKiB / 1048576).toFixed(1) + " / " + (totalKiB / 1048576).toFixed(1) + " GiB"
}
