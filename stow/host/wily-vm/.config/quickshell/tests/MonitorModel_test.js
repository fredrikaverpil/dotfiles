import { createRequire } from "node:module"
import { assert, assertEquals } from "jsr:@std/assert"

const Monitor = createRequire(import.meta.url)("../plugins/panels/monitor/Model.js")

Deno.test("monitor scale cleanup rounds to valid Hyprland divisors", () => {
  assertEquals(Monitor.normalizeScale("1.6"), "1.6")
  assertEquals(Monitor.normalizeScale("invalid"), "")
  assertEquals(Monitor.cleanScale(1, 1280, 800), "1")
  assertEquals(Monitor.cleanScale(0, 1280, 800), "")
  const scale = Monitor.cleanScale(1.25, 1920, 1080)
  assert(Number(scale) >= 1.25)
  assertEquals(43200 % Math.round(Number(scale) * 120), 0)
  assertEquals(Monitor.matchingScaleIndex([1, 1.25, 1.6, 2], 2, 1280, 800), 3)
  assertEquals(Monitor.availableScales([1, 1.25, 1.6, 2], 1920, 1080).length > 0, true)
  assertEquals(Monitor.gdkScale(1.6), 2)
})

Deno.test("monitor parser normalizes both compositor response shapes", () => {
  assertEquals(Monitor.focusedMonitor('[{"name":"A","width":1,"focused":false},{"name":"B","width":2,"focused":true}]', false), { name: "B", width: 2, focused: true })
  assertEquals(Monitor.focusedMonitor('{"name":"Virtual-1","modes":[{"width":1280,"height":800,"refresh_rate":60000}],"current_mode":0,"logical":{"scale":2}}', true), {
    name: "Virtual-1", width: 1280, height: 800, refreshRate: 60, scale: 2,
  })
  assertEquals(Monitor.focusedMonitor("invalid", true), null)
})
