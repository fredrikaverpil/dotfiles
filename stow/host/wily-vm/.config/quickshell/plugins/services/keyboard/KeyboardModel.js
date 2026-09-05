// Current layout index out of the two shapes Ui/Compositor.qml's layoutQuery
// can return. Qt-free so it can be unit tested under deno (tests/).
//
// -1 means the reading did not settle it, which leaves the caller on what it
// already had rather than guessing at zero.

function currentIndex(text, niri) {
  var parsed

  try {
    parsed = JSON.parse(String(text || ""))
  } catch (error) {
    return -1
  }

  if (!parsed || typeof parsed !== "object") return -1

  if (niri) return asIndex(parsed.current_idx)

  // `main` is Hyprland's own mark for the keyboard the seat types on. Every
  // device shares an index here because switches are applied to `all`, so the
  // first one is as good an answer when nothing is marked.
  var keyboards = Array.isArray(parsed.keyboards) ? parsed.keyboards : []
  var main = keyboards.find(function (keyboard) { return keyboard && keyboard.main }) || keyboards[0]
  return main ? asIndex(main.active_layout_index) : -1
}

// Number(undefined) is NaN but Number(null) is 0, so a missing field has to be
// rejected before the conversion rather than after it.
function asIndex(value) {
  if (typeof value !== "number") return -1
  return Number.isInteger(value) && value >= 0 ? value : -1
}

if (typeof module !== "undefined") {
  module.exports = { currentIndex: currentIndex }
}
