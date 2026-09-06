import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const Shell = createRequire(import.meta.url)("../ShellModel.js")

const dark = { bg: "#1C1917", fg: "#B4BDC3" }
const light = { bg: "#F0EDEC", fg: "#2C363C" }

Deno.test("KDE palette writes encode colours without Qt runtime helpers", () => {
  assertEquals(Shell.rgb("#1C1917"), "28,25,23")
  assertEquals(Shell.rgb("invalid"), "")
  assertEquals(Shell.kdeglobalsWrite(true, dark, light), "kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key BackgroundNormal '28,25,23'; kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key ForegroundNormal '180,189,195'; ")
  assertEquals(Shell.kdeglobalsWrite(false, dark, light), "kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key BackgroundNormal '240,237,236'; kwriteconfig6 --notify --file kdeglobals --group 'Colors:View' --key ForegroundNormal '44,54,60'; ")
})

Deno.test("text scale parsing distinguishes invalid values from valid limits", () => {
  assertEquals(Shell.textScale("1.25"), 1.25)
  assertEquals(Shell.textScale(0.7), null)
  assertEquals(Shell.textScale(1.6), null)
  assertEquals(Shell.textScale(null), null)
  assertEquals(Shell.observedTextScale(" 1.1\n"), 1.1)
  assertEquals(Shell.observedTextScale("invalid"), null)
  assertEquals(Shell.observedTextScale(0), null)
})

Deno.test("panel claims close only visible competing panels", () => {
  const claimed = { shown: true }
  const visible = { shown: true }
  assertEquals(Shell.panelsToClose([claimed, visible, { shown: false }, null], claimed), [visible])
})
