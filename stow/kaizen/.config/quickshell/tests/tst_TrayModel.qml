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

  function test_visible_count_data() {
    return [
      { tag: "all fit exactly", count: 4, maxWidth: 236, want: 4 },
      { tag: "one short keeps an overflow slot", count: 4, maxWidth: 235, want: 2 },
      { tag: "unbounded", count: 4, maxWidth: Infinity, want: 4 },
      { tag: "room for overflow only", count: 4, maxWidth: 56, want: 0 },
      { tag: "negative", count: 4, maxWidth: -50, want: 0 },
      { tag: "empty", count: 0, maxWidth: 0, want: 0 }
    ]
  }

  function test_visible_count(data) {
    verify(Tray.visibleCount(data.count, data.maxWidth, 56, 4) === data.want)
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
}
