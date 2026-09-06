function secondsFromConfig(value, fallback) {
  var seconds = Number(value)
  if (!isFinite(seconds) || seconds < 0) return fallback
  return Math.floor(seconds)
}

if (typeof module !== "undefined") {
  module.exports = {
    secondsFromConfig: secondsFromConfig
  }
}
