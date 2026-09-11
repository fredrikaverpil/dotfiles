import QtQuick
import QtTest
import "../Ui/CompositorModel.js" as Compositor
import "../Ui/compositors/Hyprland.js" as Hyprland
import "../Ui/compositors/Niri.js" as Niri

TestCase {
  name: "CompositorModel"

  function test_selection_data() {
    return [
      { tag: "Hyprland", environment: { HYPRLAND_INSTANCE_SIGNATURE: "instance" }, want: "hyprland" },
      { tag: "niri", environment: { NIRI_SOCKET: "/run/user/1000/niri.sock" }, want: "niri" }
    ]
  }

  function test_selection(data) {
    compare(Compositor.select(name => data.environment[name]).id, data.want)
  }

  function test_unsupported_session_data() {
    return [
      { tag: "unknown", environment: {} },
      { tag: "empty", environment: { NIRI_SOCKET: "", HYPRLAND_INSTANCE_SIGNATURE: "" } },
      { tag: "ambiguous", environment: { NIRI_SOCKET: "niri", HYPRLAND_INSTANCE_SIGNATURE: "hyprland" } }
    ]
  }

  function test_unsupported_session(data) {
    let error = ""
    try { Compositor.select(name => data.environment[name]) } catch (e) { error = String(e) }
    verify(error.indexOf("Unsupported or ambiguous compositor session") >= 0)
  }

  function test_scale_edits() {
    compare(Hyprland.scaleEdits("1.25", 1), [
      "-e", "s|^local wily_monitor_scale = .*|local wily_monitor_scale = 1.25|",
      "-e", "s|^local wily_gdk_scale = .*|local wily_gdk_scale = 1|"
    ])
    compare(Niri.scaleEdits("1.25", 1), [
      "-e", "s|^( *scale ).*|\\11.25|",
      "-e", "s|^( *GDK_SCALE ).*|\\1\"1\"|"
    ])
  }

  function test_theme_edits() {
    const palette = { dim: "#403833" }
    compare(Niri.themeEdits(palette), [
      "-e", "s|^( *inactive-color ).*|\\1\"#403833\"|"
    ])
    compare(Hyprland.themeEdits(palette), [
      "-e", "s|^( *inactive_border = ).*|\\1\"rgb(403833)\",|"
    ])
  }

  function test_scale_policy() {
    compare(Hyprland.cleanScale(1, 1280, 800), "1")
    compare(Hyprland.cleanScale(0, 1280, 800), "")
    const scale = Hyprland.cleanScale(1.25, 1920, 1080)
    verify(Number(scale) >= 1.25)
    compare(43200 % Math.round(Number(scale) * 120), 0)
    verify(Number(Hyprland.cleanScale(0.001, 1280, 800)) > 0)
    verify(Hyprland.availableScales([1, 1.25, 1.6, 2], 1920, 1080).length > 0)
    compare(Niri.cleanScale(1.25, 1920, 1080), "1.25")
    compare(Niri.cleanScale(0, 1920, 1080), "")
    compare(Niri.availableScales([1, 1.25, 1.6, 2], 1920, 1080), ["1", "1.25", "1.6", "2"])
  }

  function test_output_parsers() {
    const monitor = { name: "Virtual-1", width: 1280, height: 800, refreshRate: 60, scale: 2 }
    const other = Object.assign({}, monitor, { name: "Other", focused: false })
    const focused = Object.assign({}, monitor, { focused: true })
    compare(Hyprland.focusedMonitor(JSON.stringify([other, focused])), monitor)
    compare(Hyprland.focusedMonitor(JSON.stringify([other])), Object.assign({}, monitor, { name: "Other" }))
    compare(Niri.focusedMonitor('{"name":"Virtual-1","modes":[{"width":1280,"height":800,"refresh_rate":60000}],"current_mode":0,"logical":{"scale":2}}'), monitor)
    compare(Niri.focusedMonitor('{"current_mode":null,"logical":{}}'), null)
    for (const raw of ["invalid", "", "null", "{}", "[]"]) {
      compare(Hyprland.focusedMonitor(raw), null, raw)
      compare(Niri.focusedMonitor(raw), null, raw)
    }
  }
}
