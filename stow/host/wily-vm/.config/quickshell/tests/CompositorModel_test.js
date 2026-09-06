import { createRequire } from "node:module"
import { assertEquals, assertMatch } from "jsr:@std/assert"

const Compositor = createRequire(import.meta.url)("../Ui/CompositorModel.js")

Deno.test("compositor commands select the niri and Hyprland backends", () => {
  assertEquals(Compositor.dpms(true, true), ["niri", "msg", "action", "power-on-monitors"])
  assertEquals(Compositor.dpms(false, false), ["hyprctl", "dispatch", 'hl.dsp.dpms("off")'])
  assertEquals(Compositor.closeWindow(true), ["niri", "msg", "action", "close-window"])
  assertEquals(Compositor.closeWindow(false), ["hyprctl", "dispatch", "hl.dsp.window.close()"])
  assertEquals(Compositor.focusWorkspace(true, 3), ["niri", "msg", "action", "focus-workspace", "3"])
  assertEquals(Compositor.focusWorkspace(false, 3), ["hyprctl", "dispatch", 'hl.dsp.focus({ workspace = "3" })'])
  assertEquals(Compositor.outputs(true), ["niri", "msg", "-j", "focused-output"])
  assertEquals(Compositor.outputs(false), ["hyprctl", "-j", "monitors"])
  assertEquals(Compositor.setScale(true, "Virtual-1", "1280x800@60", "1.25"), [
    "niri", "msg", "output", "Virtual-1", "scale", "1.25",
  ])
  assertEquals(Compositor.setScale(false, "DP-1", "1920x1080@60", "1.25"), [
    "hyprctl", "eval", 'hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "auto", scale = 1.25 })',
  ])
  assertEquals(Compositor.layoutQuery(true), ["niri", "msg", "-j", "keyboard-layouts"])
  assertEquals(Compositor.layoutQuery(false), ["hyprctl", "-j", "devices"])
  assertEquals(Compositor.setLayout(true, 1), ["niri", "msg", "action", "switch-layout", "1"])
  assertEquals(Compositor.setLayout(false, 1), ["hyprctl", "switchxkblayout", "all", "1"])
})

Deno.test("scale edit expressions remain anchored to both persisted configurations", async () => {
  assertEquals(Compositor.scaleEdits(false, "1.25", 1), [
    "-e", "s|^local wily_monitor_scale = .*|local wily_monitor_scale = 1.25|",
    "-e", "s|^local wily_gdk_scale = .*|local wily_gdk_scale = 1|",
  ])
  assertEquals(Compositor.scaleEdits(true, "1.25", 1), [
    "-e", "s|^( *scale ).*|\\11.25|",
    "-e", "s|^( *GDK_SCALE ).*|\\1\"1\"|",
  ])

  const hypr = await Deno.readTextFile("../hypr/monitors.lua")
  const niri = await Deno.readTextFile("../niri/config.kdl")
  assertMatch(hypr, /^local wily_monitor_scale = /m)
  assertMatch(hypr, /^local wily_gdk_scale = /m)
  assertMatch(niri, /^    scale /m)
  assertMatch(niri, /^    GDK_SCALE /m)
})

Deno.test("nightlight backend commands are complete", () => {
  const niri = Compositor.nightlightBackend(true)
  const hypr = Compositor.nightlightBackend(false)
  assertEquals(niri.probe, ["busctl", "--user", "get-property", "rs.wl-gammarelay", "/", "rs.wl.gammarelay", "Temperature"])
  assertMatch(niri.set, /Temperature q $/)
  assertEquals(hypr.probe, ["hyprctl", "hyprsunset", "temperature"])
  assertMatch(hypr.launch, /hyprsunset/)
})
