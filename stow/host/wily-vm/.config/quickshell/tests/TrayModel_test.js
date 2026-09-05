// Unit tests for TrayModel.js. The tray widget itself imports Quickshell and
// so cannot be instantiated here; this is the half of it that is pure string
// handling, which is where the bugs actually were.

import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const TrayModel = createRequire(import.meta.url)("../plugins/bar/widgets/TrayModel.js")

Deno.test("labelFor", async (t) => {
  const cases = [
    { name: "title wins", item: { title: "Signal", tooltipTitle: "sig", id: "x" }, want: "Signal" },
    { name: "falls back to tooltip", item: { title: "", tooltipTitle: "Signal", id: "x" }, want: "Signal" },
    { name: "falls back to id", item: { title: "", tooltipTitle: "", id: "nm-applet" }, want: "nm-applet" },
    { name: "nothing set", item: {}, want: "" },
    { name: "null item", item: null, want: "" },
  ]
  for (const c of cases) {
    await t.step(c.name, () => assertEquals(TrayModel.labelFor(c.item), c.want))
  }
})

Deno.test("sortItems orders by id and does not mutate", () => {
  const items = [{ id: "signal" }, { id: "dropbox" }, { id: "nm-applet" }]
  const got = TrayModel.sortItems(items)
  assertEquals(got.map(i => i.id), ["dropbox", "nm-applet", "signal"])
  assertEquals(items.map(i => i.id), ["signal", "dropbox", "nm-applet"])
})

Deno.test("themeIconName", async (t) => {
  const cases = [
    { name: "plain theme lookup", url: "image://icon/nm-device-wired", want: "nm-device-wired" },
    // Quickshell searches the app's own directory here, so the bare name would
    // not resolve against any theme and must not be checked against one.
    { name: "path fallback is not a theme lookup", url: "image://icon/steam_tray?path=/opt/steam/public", want: "" },
    { name: "other query is still a theme lookup", url: "image://icon/foo?size=22", want: "foo" },
    { name: "file url", url: "file:///tmp/icon.png", want: "" },
    { name: "absolute path", url: "/tmp/icon.png", want: "" },
    { name: "empty", url: "", want: "" },
    { name: "undefined", url: undefined, want: "" },
  ]
  for (const c of cases) {
    await t.step(c.name, () => assertEquals(TrayModel.themeIconName(c.url), c.want))
  }
})
