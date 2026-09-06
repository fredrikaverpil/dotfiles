
function currentIndex(text, niri) {
  var parsed

  try {
    parsed = JSON.parse(String(text || ""))
  } catch (error) {
    return -1
  }

  if (!parsed || typeof parsed !== "object") return -1

  if (niri) return asIndex(parsed.current_idx)

  var keyboards = Array.isArray(parsed.keyboards) ? parsed.keyboards : []
  var main = keyboards.find(function (keyboard) { return keyboard && keyboard.main }) || keyboards[0]
  return main ? asIndex(main.active_layout_index) : -1
}

function asIndex(value) {
  if (typeof value !== "number") return -1
  return Number.isInteger(value) && value >= 0 ? value : -1
}

if (typeof module !== "undefined") {
  module.exports = { currentIndex: currentIndex }
}
