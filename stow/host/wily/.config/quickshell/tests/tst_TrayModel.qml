import QtQuick
import QtTest
import "../plugins/bar/widgets/TrayModel.js" as Tray

TestCase {
  name: "TrayModel"

  function test_label_data() {
    return [
      { tag: "title wins", item: { title: "Signal", tooltipTitle: "sig", id: "x" }, want: "Signal" },
      { tag: "tooltip", item: { title: "", tooltipTitle: "Signal", id: "x" }, want: "Signal" },
      { tag: "id", item: { title: "", tooltipTitle: "", id: "nm-applet" }, want: "nm-applet" },
      { tag: "empty", item: {}, want: "" },
      { tag: "null", item: null, want: "" }
    ]
  }

  function test_label(data) {
    compare(Tray.labelFor(data.item), data.want)
  }

  function test_sort_preserves_input() {
    const items = [{ id: "signal" }, { id: "dropbox" }, { id: "nm-applet" }]
    compare(Tray.sortItems(items).map(i => i.id), ["dropbox", "nm-applet", "signal"])
    compare(items.map(i => i.id), ["signal", "dropbox", "nm-applet"])
  }

  function test_theme_icon_data() {
    return [
      { tag: "theme lookup", url: "image://icon/nm-device-wired", want: "nm-device-wired" },
      { tag: "path fallback", url: "image://icon/steam_tray?path=/opt/steam/public", want: "" },
      { tag: "other query", url: "image://icon/foo?size=22", want: "foo" },
      { tag: "file URL", url: "file:///tmp/icon.png", want: "" },
      { tag: "absolute path", url: "/tmp/icon.png", want: "" },
      { tag: "empty", url: "", want: "" },
      { tag: "undefined", url: undefined, want: "" }
    ]
  }

  function test_theme_icon(data) {
    compare(Tray.themeIconName(data.url), data.want)
  }

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
    verify(Tray.step(data.rows, data.current, data.forward) === data.want)
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
    compare(Tray.place(data.anchor, 200, 100, 1000, 600), data.want)
  }
}
