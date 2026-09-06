// Current layout index out of the two shapes Ui/Compositor.qml's layoutQuery
// can return. Qt-free so it can be unit tested under deno (tests/).
//
// -1 means unknown: the caller keeps what it had rather than guessing at zero.

function currentIndex(text, niri) {
  var parsed

  try {
    parsed = JSON.parse(String(text || ""))
  } catch (error) {
    return -1
  }

  if (!parsed || typeof parsed !== "object") return -1

  if (niri) return asIndex(parsed.current_idx)

  // `main` is Hyprland's mark for the keyboard the seat types on. Switches go
  // to `all`, so every device shares an index and the first will do.
  var keyboards = Array.isArray(parsed.keyboards) ? parsed.keyboards : []
  var main = keyboards.find(function (keyboard) { return keyboard && keyboard.main }) || keyboards[0]
  return main ? asIndex(main.active_layout_index) : -1
}

// Number(null) is 0, so a missing field must be rejected before conversion.
function asIndex(value) {
  if (typeof value !== "number") return -1
  return Number.isInteger(value) && value >= 0 ? value : -1
}

if (typeof module !== "undefined") {
  module.exports = { currentIndex: currentIndex }
}
