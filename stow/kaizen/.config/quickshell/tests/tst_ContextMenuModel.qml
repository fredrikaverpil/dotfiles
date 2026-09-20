import QtQuick
import QtTest
import "../Ui/ContextMenuModel.js" as Model

TestCase {
  name: "ContextMenuModel"

  function test_step_data() {
    const rows = [{ isSeparator: false }, { isSeparator: true }, { isSeparator: false }]
    return [
      { tag: "none forward", rows: rows, current: -1, forward: true, want: 0 },
      { tag: "none backward", rows: rows, current: -1, forward: false, want: 2 },
      { tag: "skips separator", rows: rows, current: 0, forward: true, want: 2 },
      { tag: "wraps forward", rows: rows, current: 2, forward: true, want: 0 },
      { tag: "wraps backward", rows: rows, current: 0, forward: false, want: 2 },
      { tag: "separators only", rows: [{ isSeparator: true }], current: -1, forward: true, want: -1 },
      { tag: "empty", rows: [], current: -1, forward: true, want: -1 }
    ]
  }

  function test_step(data) {
    verify(Model.step(data.rows, data.current, data.forward) === data.want)
  }

  // 200x100 card in a 1000x600 area.
  function test_place_data() {
    return [
      { tag: "centered", anchor: null, want: { x: 400, y: 250 } },
      { tag: "below button", anchor: { below: true, x: 500, width: 28 }, want: { x: 500, y: 0 } },
      { tag: "below button at right edge", anchor: { below: true, x: 960, width: 28 }, want: { x: 792, y: 0 } },
      { tag: "submenu right", anchor: { x: 100, width: 200, y: 50 }, want: { x: 302, y: 44 } },
      { tag: "submenu flips left", anchor: { x: 700, width: 200, y: 50 }, want: { x: 498, y: 44 } },
      { tag: "submenu clamped to top", anchor: { x: 100, width: 200, y: 2 }, want: { x: 302, y: 0 } },
      { tag: "submenu clamped above bottom", anchor: { x: 100, width: 200, y: 580 }, want: { x: 302, y: 492 } }
    ]
  }

  function test_place(data) {
    compare(Model.place(data.anchor, 200, 100, 1000, 600), data.want)
  }
}
