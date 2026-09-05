// Unit tests for BatteryModel.js, the layer that needs no Qt at all.
//
// The model files are QML-flavoured JS with a `module.exports` guard, not ES
// modules, so they are pulled in through node compat rather than `import`.
// This is the whole reason the guard is there.

import { createRequire } from "node:module"
import { assertEquals } from "jsr:@std/assert"

const BatteryModel = createRequire(import.meta.url)("./BatteryModel.js")

Deno.test("iconFor", async (t) => {
  const cases = [
    { name: "empty", percent: 0, charging: false, want: "󰂎" },
    { name: "half", percent: 50, charging: false, want: "󰁾" },
    { name: "full", percent: 100, charging: false, want: "󰁹" },
    { name: "charging wins over level", percent: 50, charging: true, want: "󰂄" },
    { name: "above range clamps", percent: 140, charging: false, want: "󰁹" },
    { name: "below range clamps", percent: -20, charging: false, want: "󰂎" },
    { name: "unparseable falls back to empty", percent: "n/a", charging: false, want: "󰂎" },
  ]
  for (const c of cases) {
    await t.step(c.name, () => {
      assertEquals(BatteryModel.iconFor(c.percent, c.charging), c.want)
    })
  }
})

Deno.test("isLow", async (t) => {
  const cases = [
    { name: "under threshold", percent: 5, charging: false, want: true },
    { name: "on threshold", percent: BatteryModel.LOW_THRESHOLD, charging: false, want: true },
    { name: "over threshold", percent: 40, charging: false, want: false },
    { name: "charging is never low", percent: 5, charging: true, want: false },
    { name: "unknown is never low", percent: null, charging: false, want: false },
  ]
  for (const c of cases) {
    await t.step(c.name, () => {
      assertEquals(BatteryModel.isLow(c.percent, c.charging), c.want)
    })
  }
})

Deno.test("label", async (t) => {
  const cases = [
    { name: "rounds", percent: 41.6, charging: false, want: "42%" },
    { name: "marks charging", percent: 41.6, charging: true, want: "42% ↑" },
    { name: "unknown", percent: undefined, charging: false, want: "--%" },
  ]
  for (const c of cases) {
    await t.step(c.name, () => {
      assertEquals(BatteryModel.label(c.percent, c.charging), c.want)
    })
  }
})
